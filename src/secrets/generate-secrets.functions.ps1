$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'
#from 1 password
# function Create-SealedSecret {
#     [CmdletBinding()]
#     param (
#         [string]$namespace,
#         [string]$base,
#         [string]$onePassPath,
#         [string]$secretName,
#         [string]$secretKey
#     )
    
    
    
#     $secret = op read $onePassPath
#     $outputfile = "$base/$secretName.secret.yaml"
#     kubectl create secret generic --dry-run=client -o yaml --namespace $namespace  $secretName --from-literal="$secretKey"="$secret" > $outputfile
#     $base_l = $base.Replace('C:/','/mnt/c/')
#     wsl -d debian -- /usr/local/bin/kubeseal --cert "$base_l/../../../sealed-secrets.pem" -f $outputfile.Replace('C:/','/mnt/c/') -w $outputfile.Replace('C:/','/mnt/c/').Replace('.secret.yaml','.sealed.yaml')

# }

function Create-SealedSecret {
    [CmdletBinding()]
    param (
        [string]$namespace,
        [string]$base,
        [string]$onePassPath,
        [string]$secretName,
        [string]$secretKey
    )
    Create-SealedSecretMany -namespace $namespace -base $base -secretName $secretName  -secrets @{$secretKey = $onePassPath }
}

function Create-SealedSecretMany {
    [CmdletBinding()]
    param (
        [string]$namespace,
        [string]$base,
        [string]$secretName,
        [hashtable]$secrets
    )
    
    $kubectlParams = @("create", "secret", "generic", $secretName, "--dry-run=client", "--output=yaml", "--namespace=$namespace")
    foreach ($currentItemName in $secrets.Keys) {
        $secret = op read $secrets.Item($currentItemName)
        $kubectlParams += "--from-literal=$currentItemName=$secret"
    }
        
    
    $outputfile = "$base/$secretName.secret.yaml"
    
    Write-Debug "kubectl $($kubectlParams -join ' ')"
    & "kubectl" $kubectlParams > $outputfile
    $base_l = $base.Replace('C:/', '/mnt/c/')
    $sealedFile = $outputfile.Replace('C:/', '/mnt/c/').Replace('.secret.yaml', '.sealed.yaml')
    wsl -- /usr/local/bin/kubeseal --cert "$base_l/../../../sealed-secrets.pem" -f $outputfile.Replace('C:/', '/mnt/c/') -w $sealedFile
    Write-Host "Generated $secretname in $sealedFile"
}

function Create-ImagePullSecret {
    [CmdletBinding()]
    param (
        [string]$namespace,
        [string]$base,
        [string]$secretname = 'esyn-registry',
        [string]$registry = "cresyn001",
        [string]$registrydns = "$registry.azurecr.io"
    )
        
    $acrusername = (az acr credential show -n $registry --query username).Replace('"', '')
    $acrpassword = (az acr credential show -n $registry --query passwords[0].value).Replace('"', '')
    write-debug "acrusername: $acrusername"
    
    $outputfile = "$base/$secretName.secret.yaml"
    kubectl create secret docker-registry $secretname --namespace $namespace --docker-server=$registrydns --docker-username="$acrusername" --docker-password="$acrpassword" --docker-email='nowhere@nowhere' --dry-run=client --output=yaml > $outputfile
    
    $base_l = $base.Replace('C:/', '/mnt/c/')
    $sealedFile = $outputfile.Replace('C:/', '/mnt/c/').Replace('.secret.yaml', '.sealed.yaml')
    wsl -- /usr/local/bin/kubeseal --cert "$base_l/../../../sealed-secrets.pem" -f $outputfile.Replace('C:/', '/mnt/c/') -w $sealedFile
    Write-debug "Generated $secretname in $sealedFile"

}

function SealedSecret {
    [CmdletBinding()]
    param (
        [string]$base,
        [string]$outputfile
    )
    $outputfile = $outputfile.Replace('\', '/')

    $base_l = $base.Replace('C:/', '/mnt/c/')
    $sealedFile = $outputfile.Replace('C:/', '/mnt/c/').Replace('.secret.yaml', '.sealed.yaml')
    write-debug "wsl -- /usr/local/bin/kubeseal --cert `"$base_l/../../../sealed-secrets.pem`" -f $($outputfile.Replace('C:/', '/mnt/c/')) -w $sealedFile"
    wsl -- /usr/local/bin/kubeseal --cert "$base_l/../../../sealed-secrets.pem" -f $outputfile.Replace('C:/', '/mnt/c/') -w $sealedFile
    Write-debug "Generated $secretname in $sealedFile"

}
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



# foreach ($item in $secrets) {
#     $secret = op read "op://mst-cew-preprod/$($item.id)"
#     $secret
# }




# $base_test = "$gitRoot/deploy/chart/esyn-platform-test"
# $base_preprod = "$gitRoot/deploy/chart/esyn-platform-preprod"
# $base_prod = "$gitRoot/deploy/chart/esyn-platform-prod"

# Create-SealedSecret "$base_udv/templates/secrets/saml-keycloak" "op://esyn/eSyn - udv - saml.keycloak - admin/nemlog-in private certificat" "keycloak-config-cli-secrets" "esyn-keycloak-saml"
# Create-SealedSecret "$base_test/templates/secrets/saml-keycloak" "op://esyn/eSyn - test - saml.keycloak - admin/nemlog-in private certificat" "keycloak-config-cli-secrets" "esyn-keycloak-saml"

#Create-SealedSecret "$base_udv/templates/secrets/esyn-app" "op://esyn/eSyn - udv - appin-fstyr-esyn-udv/ConnectionString" "esyn-applicationinsights" "ConnectionString" "esyn-app"
#Create-SealedSecret "$base_test/templates/secrets/esyn-app" "op://esyn/eSyn - test - appin-fstyr-esyn-test/ConnectionString" "esyn-applicationinsights" "ConnectionString" "esyn-app"
#Create-SealedSecret "$base_preprod/templates/secrets/esyn-app" "op://esyn/eSyn - preprod - appin-fstyr-esyn-preprod/ConnectionString" "esyn-applicationinsights" "ConnectionString" "esyn-app"
#Create-SealedSecret -namespace "esyn-app" -base "$base_prod/templates/secrets/esyn-app" -onePassPath "op://esyn/eSyn - prod - appin-fstyr-esyn-prod/ConnectionString" -secretName "esyn-applicationinsights" -secretKey "ConnectionString"

#Create-SealedSecretMany -base "$base_udv/templates/secrets/esyn-app" -secretName "fs-fshare-p01" -namespace "esyn-app" -secrets @{"username"="op://esyn/eSyn - SIT file share - fs-fshare-p01/username";"password"="op://esyn/eSyn - SIT file share - fs-fshare-p01/password"}
#Create-SealedSecretMany -base "$base_test/templates/secrets/esyn-app" -secretName "fs-fshare-p01" -namespace "esyn-app" -secrets @{"username"="op://esyn/eSyn - SIT file share - fs-fshare-p01/username";"password"="op://esyn/eSyn - SIT file share - fs-fshare-p01/password"}
#Create-SealedSecretMany -base "$base_preprod/templates/secrets/esyn-app" -secretName "fs-fshare-p01" -namespace "esyn-app" -secrets @{"username"="op://esyn/eSyn - SIT file share - fs-fshare-p01/username";"password"="op://esyn/eSyn - SIT file share - fs-fshare-p01/password"}

#create registry imagepullsecret
# Create-ImagePullSecret -namespace 'esyn-keycloak-saml' -base "$base_udv/templates/secrets/saml-keycloak"
# Create-ImagePullSecret -namespace 'esyn-keycloak-saml' -base "$base_test/templates/secrets/saml-keycloak"
# Create-ImagePullSecret -namespace 'esyn-keycloak-saml' -base "$base_preprod/templates/secrets/saml-keycloak"
# Create-ImagePullSecret -namespace 'esyn-keycloak-saml' -base "$base_prod/templates/secrets/saml-keycloak"

# SealedSecret -base "$base_preprod/templates/secrets/esyn-app" -outputfile "C:\udv\fstyr\esyn-server-setup\deploy\chart\esyn-platform-preprod\templates\secrets\esyn-app\esyn-app.esyn-tls-api-gateway.secret.yaml"
# SealedSecret -base "$base_preprod/templates/secrets/esyn-app" -outputfile "C:\udv\fstyr\esyn-server-setup\deploy\chart\esyn-platform-preprod\templates\secrets\esyn-app\esyn-app.esyn-tls-auth-gateway-esyn.secret.yaml"
# SealedSecret -base "$base_preprod/templates/secrets/esyn-app" -outputfile "C:\udv\fstyr\esyn-server-setup\deploy\chart\esyn-platform-preprod\templates\secrets\esyn-app\esyn-app.esyn-tls-auth-gateway-inspection.secret.yaml"
# SealedSecret -base "$base_preprod/templates/secrets/saml-keycloak" -outputfile "C:\udv\fstyr\esyn-server-setup\deploy\chart\esyn-platform-preprod\templates\secrets\saml-keycloak\esyn-keycloak-saml.esyn-tls.secret.yaml"
# SealedSecret -base "$base_preprod/templates/secrets/sso-keycloak" -outputfile "C:\udv\fstyr\esyn-server-setup\deploy\chart\esyn-platform-preprod\templates\secrets\sso-keycloak\esyn-keycloak-sso.esyn-tls.secret.yaml"