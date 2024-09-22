BeforeAll {
    . $PSScriptRoot/generate-secrets.fakedata.ps1
    . $PSScriptRoot/generate-secrets.functions.ps1
}

Describe 'ConvertTo-KubeSecret' {
    It 'generic secret is success' {
        $expected = 
        "apiVersion: v1
data:
  password: YXNk
  username: YWRtaW4=
kind: Secret
metadata:
  creationTimestamp: null
  name: keycloak-admin
  namespace: cew-keycloak"
        $result = ConvertTo-KubeSecret $fakesecret2 "cew-keycloak"
        ($result -join "`r`n") | Should -Be $expected
    }

    It 'is missing name' {
        { throw ConvertTo-KubeSecret $fakesecret_missing_name "cew-keycloak" } | Should -Throw "name missing on item *"
    }


    ### docker type


    It 'docker registry is success' {
        $expected = 
        "apiVersion: v1
data:
  .dockerconfigjson: eyJhdXRocyI6eyJjcml0cGxhdGZvcm11ZHYwMDEuYXp1cmVjci5pbyI6eyJ1c2VybmFtZSI6Im1zdC1jZXctdWR2MDEiLCJwYXNzd29yZCI6IlBCS1BIMWVQa2VCZXp0MktzbWk5c0lQMTAzdHQzUnJSZVVwY05pd3VjaCtBQ1JCTDR2ejUiLCJlbWFpbCI6Iidub3doZXJlQG5vd2hlcmUnIiwiYXV0aCI6ImJYTjBMV05sZHkxMVpIWXdNVHBRUWt0UVNERmxVR3RsUW1WNmRESkxjMjFwT1hOSlVERXdNM1IwTTFKeVVtVlZjR05PYVhkMVkyZ3JRVU5TUWt3MGRubzEifX19
kind: Secret
metadata:
  creationTimestamp: null
  name: regcred
  namespace: cew-keycloak
type: kubernetes.io/dockerconfigjson"
        $result = ConvertTo-KubeSecret $fakesecret_docker "cew-keycloak"
    ($result -join "`r`n") | Should -Be $expected
    }

}


Describe 'Get-Namespaces' {
    It 'is missing namespace' {
        { throw Get-Namespaces $fakesecret_missing_namespace } | Should -Throw "namespace missing on secret *"
    }

    It 'Get-Namespaces is success' {

        #test get-namespace
        $result = Get-Namespaces $fakesecret2 $namespace
        $result | Should -Be "cew-keycloak"
    } 

    It 'Get-Namespaces test should' {

        #test get-namespace
        $result = Get-Namespaces $fakesecret_multi_namespace $namespace
        $result | Should -Be "cew-keycloak", "namespace2", "namespace3"
    } 

    It 'Get-Namespaces is success (bug)' {

        #test get-namespace
        $result = Get-Namespaces $fakesecret_bug_missing_namespace $namespace
        $result | Should -Be "cew-keycloak"
    } 

    
}

Describe 'Get-SecretList' {
    Context "secretlist for env:cloud" {
        BeforeEach{
            Mock Get-SecretListRaw {return $fakesecrets_list} -Verifiable -ParameterFilter {$vault -eq 'testvault'}

            $result = Get-SecretList -vault 'testvault' -env 'cloud'
        }

        It "did call raw list" {
            Should -InvokeVerifiable
        }

        It "only contains env:cloud" {
            ($result | %{$_.tags -contains 'env:cloud'} ) -contains $false | Should -be $false
        }

        It "contains env:cloud" {
            $item = $result | ?{$_.tags -contains 'env:cloud'}
            $item.id | Should -be 'b25ypz6mthzzwgwn2aoi4yt6em'
        }
    }

    Context "secretlist for env:udv" {
        BeforeEach{
            Mock Get-SecretListRaw {return $fakesecrets_list} -Verifiable -ParameterFilter {$vault -eq 'testvault'}

            $result = Get-SecretList -vault 'testvault' -env ' udv'
        }

        It "did call raw list" {
            Should -InvokeVerifiable
        }

        It "only contains env:udv" {
            ($result | %{$_.tags -contains 'env: udv'} ) -contains $false | Should -be $false
        }

        It "contains env:udv" {
            
            $result[0].id | Should -be 'x5ajnu4h4q4zeiqy6cyhelufze'
        }
    }
}