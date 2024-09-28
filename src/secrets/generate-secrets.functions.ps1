$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'
#--------------------------------------------------------------------------------------------
function ConvertTo-KubeSecret {
    [CmdletBinding()]
    param (
        $item,
        # [string]$namespace,
        # [string]$secretName,
        # [hashtable]$secrets
        $namespace
    )
    Write-Debug "ConvertTo-KubeSecret"
    #$item
    $name = $item.fields | where { $_.label -eq 'name' }

    $file_publicKey = "$([System.Guid]::NewGuid())_publickey"
    $file_privateKey = "$([System.Guid]::NewGuid())_privatekey"

    if ($null -eq $name) {
        throw "name missing on item $($item.id)"
    }

    if($item.tags -contains 'docker-registry'){
      $docker_usernameField = $item.fields | where { $_.label -eq 'username' }
      if ($null -eq $docker_usernameField) {
          throw "docker username missing on item $($item.id)"
      }
      $docker_serverField = $item.fields | where { $_.label -eq 'docker-server' }
      if ($null -eq $docker_serverField) {
          throw "docker server missing on item $($item.id)"
      }
      $docker_passwordField = $item.fields | where { $_.label -eq 'password' }
      if ($null -eq $docker_passwordField) {
          throw "password missing on item $($item.id)"
      }
      #kubectl create secret docker-registry $secretname --namespace $namespace --docker-server=$registrydns --docker-username="$acrusername" --docker-password="$acrpassword" --docker-email='nowhere@nowhere' --dry-run=client --output=yaml > $outputfile
      $kubectlParams = @("create", "secret", "docker-registry", $($name.value), "--dry-run=client", "--output=yaml", "--namespace=$($namespace)", "--docker-server=$($docker_serverField.value)", "--docker-username=$($docker_usernameField.value)", "--docker-password=$($docker_passwordField.value)", "--docker-email='nowhere@nowhere'" )
      $kubectlParams_debug = $kubectlParams

    }elseif($item.tags -contains 'tls'){
        #kubectl create secret tls tls-secret --cert=path/to/tls.cert --key=path/to/tls.key
        $tls_publicKey = $item.fields | where { $_.label -eq 'publickey' }
        if ($null -eq $tls_publicKey) {
            throw "tls public key missing on item $($item.id)"
        }
        $tls_privateKey = $item.fields | where { $_.label -eq 'privatekey' }
        if ($null -eq $tls_privateKey) {
            throw "tls private key missing on item $($item.id)"
        }
        

        Set-Content -path $file_publicKey -value $tls_publicKey.value.Replace("-----BEGIN CERTIFICATE-----", "-----BEGIN CERTIFICATE-----`r`n").Replace("-----END CERTIFICATE-----", "`r`n-----END CERTIFICATE-----`r`n")
        Set-Content -path $file_privateKey -value $tls_privateKey.value.Replace("-----BEGIN PRIVATE KEY-----", "-----BEGIN PRIVATE KEY-----`r`n").Replace("-----END PRIVATE KEY-----", "`r`n-----END PRIVATE KEY-----")

        $kubectlParams = @("create", "secret", "tls", $($name.value), "--dry-run=client", "--output=yaml", "--namespace=$($namespace)", "--cert=$($file_publicKey)", "--key=$($file_privateKey)")
    }else{
      
      $kubectlParams = @("create", "secret", "generic", $($name.value), "--dry-run=client", "--output=yaml", "--namespace=$($namespace)")
      $kubectlParams_debug = $kubectlParams
      foreach ($field in $item.fields | where { $_.label -ne 'namespace' -and $_.label -ne 'name' -and $_.label -ne 'notesPlain' }) {
        $kubectlParams += "--from-literal=$($field.label)=$($field.value)"
        $kubectlParams_debug += "--from-literal=$($field.label)=<hidden>"
      }
    }

    Write-Debug "kubectl $($kubectlParams_debug -join ' ')"    
    $secretyaml = & "kubectl" $kubectlParams
    Write-Debug ($secretyaml -join "`r`n")
    Write-Output  $secretyaml

    if($item.tags -contains 'tls') {
        Remove-Item -path $file_publicKey
        Remove-Item -path $file_privateKey
    }

}

function ConvertTo-SealedSecret {
    [CmdletBinding()]
    param (
        $kubesecret,
        [string]$certpath
    )
    $kubesecret | wsl -- /usr/local/bin/kubeseal --cert $certpath
}

function Get-Secret {
    [CmdletBinding()]
    param (
        [string]$id
    )
    Write-Debug "Get-Secret"

    $result = (op item get $id --format json) | ConvertFrom-Json
    
    write-debug ("`n | $($result.id)")
    return $result
}

function Get-SecretList {
    [CmdletBinding()]
    param (
        [string]$env,
        [string]$vault
    )
    Write-Debug "Get-SecretList"
    $list = Get-SecretListRaw -vault $vault | ?{$_.tags -contains "env:$env"}
    Write-Information ("Secrets to Process:`n | $(($list | %{"$($_.id) |$($_.title)"}) -join "`n | ")")

    return $list
}

function Get-SecretListRaw {
    [CmdletBinding()]
    param (
        [string]$vault
    )
    Write-Debug "Get-SecretListRaw"
    $list = (op item list --vault $vault --tags "sealedsecret" --format json) | ConvertFrom-Json
    write-debug ("SecretListRaw: `n | $(($list | %{"$($_.id) |$($_.title)"}) -join "`n | ")")

    return $list
}

function Get-Namespaces {
  param (
    $secret
  )

  $namespaceField = $secret.fields | where { $_.label -eq 'namespace' }
  if ($null -eq $namespaceField) {
    Write-Debug "namespace missing on secret $($secret.id)"
    throw "namespace missing on secret $($secret.id)"
  }
  if($null -eq $namespaceField.value){
    Write-Debug "namespace is empty on secret $($secret.id)"
    throw "namespace is empty on secret $($secret.id)"
  }

  return $namespaceField.value.Split(';')
}

function Set-SealedSecrets {
    [CmdletBinding()]
    param (
        [string]$vault,
        [string]$env,
        [string]$outputpath,
        [string]$certpath
    )
    Write-Information "Generating sealed secrets. from vault: $vault and env: $env"
    $secrets = Get-SecretList $env $vault
    foreach ($secretstub in $secrets) {
        Write-Information "generating $($secretstub.title)"
        $secret = Get-Secret $secretstub.id

        $namespaces = Get-Namespaces $secret
        foreach ($namespace in $namespaces) {
          
          $kubesecret = ConvertTo-KubeSecret $secret $namespace
          if ($null -eq $kubesecret) {
              Continue
          }
          #$kubesecret
          $sealedsecret = ConvertTo-SealedSecret $kubesecret $certpath
          #$sealedsecret
          $name = $secret.fields | where { $_.label -eq 'name' }
      
          Out-File -FilePath "$outputpath/$namespace.$($name.value).sealed.yaml" -InputObject $sealedsecret
        }
    }
    
}