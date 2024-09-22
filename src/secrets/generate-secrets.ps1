. $PSScriptRoot/generate-secrets.functions.ps1

$gitRoot = git rev-parse --show-toplevel
$gitRoot2 = $gitRoot.Replace('C:/', '/mnt/c/')

 
Set-SealedSecrets -vault "mst-cew-preprod" -env " udv" -outputpath "$gitRoot/environments/udv/cew-platform-udv/templates/secrets" -certpath "$gitRoot2/environments/udv/kubeseal.cer" 

Set-SealedSecrets -vault "mst-cew-preprod" -env " test" -outputpath "$gitRoot/environments/test/cew-platform-Test/templates/secrets" -certpath "$gitRoot2/environments/test/kubeseal.cer"

Set-SealedSecrets -vault "mst-cew-preprod" -env "preprod" -outputpath "$gitRoot/environments/preprod/cew-platform-preprod/templates/secrets" -certpath "$gitRoot2/environments/preprod/kubeseal.cer" 