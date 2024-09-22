$fakesecrets = '[
    {
      "id": "itvdhya7pybnpfbu56o76k3uei",
      "title": "udv - keycloak - admin",
      "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
      "version": 2,
      "vault": {
        "id": "lm2ln3xcz3ldbk4y7zwag467oe",
        "name": "mst-cew-preprod"
      },
      "category": "LOGIN",
      "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
      "created_at": "2024-04-17T10:32:26Z",
      "updated_at": "2024-04-17T10:38:41Z",
      "additional_information": "admin"
    },
    {
      "id": "omthzmu5rgbyvhf46o2ibdm24e",
      "title": "udv - sqlserver - dev.keycloak.user",
      "tags": ["cew", "env: udv", "keycloak", "mst", "sealedsecret", "sqldb"],
      "version": 5,
      "vault": {
        "id": "lm2ln3xcz3ldbk4y7zwag467oe",
        "name": "mst-cew-preprod"
      },
      "category": "LOGIN",
      "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
      "created_at": "2024-04-17T08:20:17Z",
      "updated_at": "2024-04-17T11:47:05Z",
      "additional_information": "dev.keycloak.user"
    }
  ]' | ConvertFrom-Json

  $fakesecret_missing_name = '{
    "id": "omthzmu5rgbyvhf46o2ibdm24e",
    "title": "udv - sqlserver - dev.keycloak.user",
    "tags": ["cew", "env: udv", "keycloak", "mst", "sealedsecret", "sqldb"],
    "version": 5,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T08:20:17Z",
    "updated_at": "2024-04-17T11:47:05Z",
    "additional_information": "dev.keycloak.user",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "value": "dev.keycloak.user",
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "value": "asd",
        "entropy": 68.0634765625,
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/password",
        "password_details": {
          "entropy": 68,
          "generated": true,
          "strength": "FANTASTIC"
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/notesPlain"
      },
      {
        "id": "3nmjuy7wsk74722p7dyy4ddwsm",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "server",
        "value": "mst-cew-sql-udv",
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/add more/server"
      }
    ]
  }' | ConvertFrom-Json

$fakesecret1 = '{
    "id": "omthzmu5rgbyvhf46o2ibdm24e",
    "title": "udv - sqlserver - dev.keycloak.user",
    "tags": ["cew", "env: udv", "keycloak", "mst", "sealedsecret", "sqldb"],
    "version": 5,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T08:20:17Z",
    "updated_at": "2024-04-17T11:47:05Z",
    "additional_information": "dev.keycloak.user",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "value": "dev.keycloak.user",
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "value": "asd",
        "entropy": 68.0634765625,
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/password",
        "password_details": {
          "entropy": 68,
          "generated": true,
          "strength": "FANTASTIC"
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/notesPlain"
      },
      {
        "id": "3nmjuy7wsk74722p7dyy4ddwsm",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "server",
        "value": "mst-cew-sql-udv",
        "reference": "op://mst-cew-preprod/udv - sqlserver - dev.keycloak.user/add more/server"
      }
    ]
  }' | ConvertFrom-Json

  $fakesecret_missing_namespace = '{
    "id": "itvdhya7pybnpfbu56o76k3uei",
    "title": "udv - keycloak - admin",
    "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
    "version": 3,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-04-18T09:21:55Z",
    "additional_information": "admin",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "value": "admin",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "value": "asd",
        "entropy": 68.0634765625,
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/password",
        "password_details": {
          "entropy": 68,
          "generated": true,
          "strength": "FANTASTIC"
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/notesPlain"
      },
      {
        "id": "xbxzgfrtcfzlqudh5zx5bzug2m",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "name",
        "value": "keycloak-admin",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/add more/name"
      }
    ]
  }' | ConvertFrom-Json

$fakesecret2 = '{
    "id": "itvdhya7pybnpfbu56o76k3uei",
    "title": "udv - keycloak - admin",
    "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
    "version": 3,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-04-18T09:21:55Z",
    "additional_information": "admin",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "value": "admin",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "value": "asd",
        "entropy": 68.0634765625,
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/password",
        "password_details": {
          "entropy": 68,
          "generated": true,
          "strength": "FANTASTIC"
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/notesPlain"
      },
      {
        "id": "xbxzgfrtcfzlqudh5zx5bzug2m",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "name",
        "value": "keycloak-admin",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/add more/name"
      },
      {
        "id": "il7kvaadopj5stc63a2feetuyy",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "namespace",
        "value": "cew-keycloak",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/add more/namespace"
      }
    ]
  }' | ConvertFrom-Json

$fakesecret_multi_namespace = '{
    "id": "itvdhya7pybnpfbu56o76k3uei",
    "title": "udv - keycloak - admin",
    "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
    "version": 3,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-04-18T09:21:55Z",
    "additional_information": "admin",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "value": "admin",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "value": "asd",
        "entropy": 68.0634765625,
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/password",
        "password_details": {
          "entropy": 68,
          "generated": true,
          "strength": "FANTASTIC"
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/notesPlain"
      },
      {
        "id": "xbxzgfrtcfzlqudh5zx5bzug2m",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "name",
        "value": "keycloak-admin",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/add more/name"
      },
      {
        "id": "il7kvaadopj5stc63a2feetuyy",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "namespace",
        "value": "cew-keycloak;namespace2;namespace3",
        "reference": "op://mst-cew-preprod/udv - keycloak - admin/add more/namespace"
      }
    ]
  }' | ConvertFrom-Json

  $fakesecret_docker = '{
    "id": "b25ypz6mthzzwgwn2aoi4yt6em",
    "title": "cloud - critplatformudv001",
    "tags": ["docker-registry", "env:cloud", "sealedsecret"],
    "version": 2,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-19T13:29:49Z",
    "updated_at": "2024-04-22T09:03:49Z",
    "additional_information": "mst-cew-udv01",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "value": "mst-cew-udv01",
        "reference": "op://mst-cew-preprod/cloud - critplatformudv001/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "value": "PBKPH1ePkeBezt2Ksmi9sIP103tt3RrReUpcNiwuch+ACRBL4vz5",
        "reference": "op://mst-cew-preprod/cloud - critplatformudv001/password",
        "password_details": {
          "strength": "FANTASTIC"
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/cloud - critplatformudv001/notesPlain"
      },
      {
        "id": "bu7yjxuvgrr4fxnfk7ybsnnrgi",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "name",
        "value": "regcred",
        "reference": "op://mst-cew-preprod/cloud - critplatformudv001/add more/name"
      },
      {
        "id": "nlzkbgs5oh3biueiadfo3drbue",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "namespace",
        "value": "cew-keycloak",
        "reference": "op://mst-cew-preprod/cloud - critplatformudv001/add more/namespace"
      },
      {
        "id": "mj5pf5nblup7pwjyvuneges7l4",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "docker-server",
        "value": "critplatformudv001.azurecr.io",
        "reference": "op://mst-cew-preprod/cloud - critplatformudv001/add more/docker-server"
      }
    ]
  }'| ConvertFrom-Json

  $fakesecret_bug_missing_namespace = '{
    "id": "x5ajnu4h4q4zeiqy6cyhelufze",
    "title": "udv - keycloak-config-cli-secrets",
    "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
    "version": 4,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-04-19T08:56:38Z",
    "additional_information": "ΓÇö",
    "sections": [
      {
        "id": "add more"
      }
    ],
    "fields": [
      {
        "id": "username",
        "type": "STRING",
        "purpose": "USERNAME",
        "label": "username",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/username"
      },
      {
        "id": "password",
        "type": "CONCEALED",
        "purpose": "PASSWORD",
        "label": "password",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/password",
        "password_details": {
          "history": ["dynamism*comrade6inure8gauge"]
        }
      },
      {
        "id": "notesPlain",
        "type": "STRING",
        "purpose": "NOTES",
        "label": "notesPlain",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/notesPlain"
      },
      {
        "id": "xbxzgfrtcfzlqudh5zx5bzug2m",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "name",
        "value": "keycloak-config-cli-secrets",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/add more/name"
      },
      {
        "id": "il7kvaadopj5stc63a2feetuyy",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "namespace",
        "value": "cew-keycloak",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/add more/namespace"
      },
      {
        "id": "rcdno76xw4mcgaedcfrm23gpym",
        "section": {
          "id": "add more"
        },
        "type": "STRING",
        "label": "subject",
        "value": "CN = local-dev-enc, serialNumber = UI:DK-O:G:d4c2b13c-807c-4610-bf0f-7d24e21795f7, O = Testorganisation nr. 95285664, organizationIdentifier = NTRDK-95285664, C = DK",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/add more/subject"
      },
      {
        "id": "kuf2tj45mkfmcjtsmnvsusujhm",
        "section": {
          "id": "add more"
        },
        "type": "CONCEALED",
        "label": "privatekey",
        "value": "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 /G67DIV+oaMbInCkHtmy5F4=",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/add more/privatekey"
      },
      {
        "id": "wvksbkrvcy7acgtrvrqnbryphy",
        "section": {
          "id": "add more"
        },
        "type": "CONCEALED",
        "label": "publickey",
        "value": "MIIGijCCBL6gAwIBAgIUDwJagFr7ZrgLT7tWOgkiaAPc/6owQQYJKoZIhvcNAQEK MDSgDzANBglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEF AKIDAgEgMGsxLTArBgNVBAMMJERlbiBEYW5za2UgU3RhdCBPQ0VTIHVkc3RlZGVu ZGUtQ0EgMTETMBEGA1UECwwKVGVzdCAtIGN0aTEYMBYGA1UECgwPRGVuIERhbnNr ZSBTdGF0MQswCQYDVQQGEwJESzAeFw0yNDAzMjIxMjI4MTJaFw0yNzAzMjIxMjI4 MTFaMIGfMRYwFAYDVQQDDA1sb2NhbC1kZXYtZW5jMTcwNQYDVQQFEy5VSTpESy1P Okc6ZDRjMmIxM2MtODA3Yy00NjEwLWJmMGYtN2QyNGUyMTc5NWY3MSYwJAYDVQQK DB1UZXN0b3JnYW5pc2F0aW9uIG5yLiA5NTI4NTY2NDEXMBUGA1UEYQwOTlRSREst OTUyODU2NjQxCzAJBgNVBAYTAkRLMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB igKCAYEAzJPmh4YYfGVWECuTppjdMllN+25cKmZ1Qj3XQ9e8WlLd5KmYjfloJ+TL hwGrTgLXcX0lWXLUCoqWo8wonyffv26bsR4cisK035LrxEzSlqx/RN+7+V3TnYDQ 6y9S84D/A9KRxrC0YKSfgkYNlQ172wvdppOYVGWpDs4Ac9Q7uAPTSMvZMCIsVkpa nUtgf7yHdH5aok6a4PEwnDmurLWyCoQydQW4BBbWzH2ebjxUPb0Xb2eBez2McoCM WXM/TQV5/c+vTj8Djm85zLVlmYEoiKwi6JFZi5Gqh+8CBxOJiR44lP5OjCu6Cmez VWRJ6+CrKOhxNwwNwMIwnmS2KIR33IoJza/FWdYCE5s9E4RQZasMLyCSzsfKYqW4 krcNhL97+DOnF3ovwEUfbk8A1IDNjho0TGBK0nO80IpvL29oT8UrlFoTuQUDyn2V qkCwkQnNIFzkVUoKBL4GGCBf3skhEGQ0ChFwOj4lrb9nWIpKnU6NhZpAoNCPxUpB Xp7a6OaBAgMBAAGjggGHMIIBgzAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFH8o n9lxmULidefXNXYuTQglbXZeMHsGCCsGAQUFBwEBBG8wbTBDBggrBgEFBQcwAoY3 aHR0cDovL2NhMS5jdGktZ292LmRrL29jZXMvaXNzdWluZy8xL2NhY2VydC9pc3N1 aW5nLmNlcjAmBggrBgEFBQcwAYYaaHR0cDovL2NhMS5jdGktZ292LmRrL29jc3Aw IgYDVR0gBBswGTAIBgYEAI96AQEwDQYLKoFQgSkBAQEDBwEwOwYIKwYBBQUHAQME LzAtMCsGCCsGAQUFBwsCMB8GBwQAi+xJAQIwFIYSaHR0cHM6Ly91aWQuZ292LmRr MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jYTEuY3RpLWdvdi5kay9vY2VzL2lz c3VpbmcvMS9jcmwvaXNzdWluZy5jcmwwHQYDVR0OBBYEFE2dsF61NSbvTYUcZQNW dChTrRQrMA4GA1UdDwEB/wQEAwIFoDBBBgkqhkiG9w0BAQowNKAPMA0GCWCGSAFl AwQCAQUAoRwwGgYJKoZIhvcNAQEIMA0GCWCGSAFlAwQCAQUAogMCASADggGBAJ2D 5aDEBN9ErmB8IlZQi2xc49jU100Hw78ib8odUsp9DJGLLvBXW5HsG+FzhK9XjQo5 nje8Pyj3BaNIegmdKED72W+iOAvkmaJhKlSDttNKiSumae8bk+6ra2LNtwvJNQxO MGJWAjdOBi0qyP+gJJuNfX5ozB8A+tq1DZApHqplTiIsmEJKTSlqLDM/gv7BnYdR o/e8zmz1ohZR8eumTrsECOZJdCUDCLFrFlBRryT/iuO1bAOnDfeclgRaYsOgp/0y TTwhzGlx8fwyXKbAucgzwXsPlSLoV6SfDSM6X+jMzQel66MCsES8iCH8A9bV+lYu Lfv8Whg+3YNsuP48tEbOdlUtkvEIMWoW5kOzkBVCD3JpSxiW85V4IU0JIfLZyGBB PbmfbeXr8U/XkxLsSzoiStW8ZFTaS4pw+VDKhBvjPDpgFbQsf7324B0NBmIiGfUz 27LtxOspy7hwXaCyCjWn20mikSO8l3COrm4dq1aSWC6AYKLUg/J+h7HX+oJdXA==",
        "reference": "op://mst-cew-preprod/udv - keycloak-config-cli-secrets/add more/publickey"
      }
    ]
}'| ConvertFrom-Json

$fakesecrets_list = '[
  {
    "id": "x5ajnu4h4q4zeiqy6cyhelufze",
    "title": "udv - keycloak-config-cli-secrets",
    "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
    "version": 4,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-04-19T08:56:38Z",
    "additional_information": "ΓÇö"
  },
  {
    "id": "lq4z7p5sm7bvox2272kkmysram",
    "title": "udv - sqlserver - dev.cvr.user",
    "tags": ["cew", "env: udv", "mst", "sealedsecret", "sqldb"],
    "version": 2,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T08:20:17Z",
    "updated_at": "2024-04-26T10:37:30Z",
    "additional_information": "dev.cvr.user"
  },
  {
    "id": "oohy3qbc6ok6375cunngscz2nq",
    "title": "udv - sqlserver - dev.keycloak.user",
    "tags": ["cew", "env: udv", "keycloak", "mst", "sealedsecret", "sqldb"],
    "version": 1,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T08:20:17Z",
    "updated_at": "2024-04-22T11:43:02Z",
    "additional_information": "dev.keycloak.user"
  },
  {
    "id": "kgioe4uzocysyhsubmqaroj5ee",
    "title": "udv - cvr - user",
    "tags": ["MST", "ads", "env: udv", "sealedsecret"],
    "version": 2,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-05-01T12:41:58Z",
    "additional_information": "NNIT_CVR_I_SKYEN"
  },
  {
    "id": "b25ypz6mthzzwgwn2aoi4yt6em",
    "title": "cloud - critplatformudv001",
    "tags": ["docker-registry", "env:cloud", "sealedsecret"],
    "version": 3,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-19T13:29:49Z",
    "updated_at": "2024-04-22T10:29:50Z",
    "additional_information": "mst-cew-udv01"
  },
  {
    "id": "omthzmu5rgbyvhf46o2ibdm24e",
    "title": "udv - sqlserver - dev.ads.user",
    "tags": ["cew", "env: udv", "mst", "sealedsecret", "sqldb"],
    "version": 16,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T08:20:17Z",
    "updated_at": "2024-04-26T10:37:43Z",
    "additional_information": "dev.ads.user"
  },
  {
    "id": "5a7hzd77rldsgf3ay3wcsqelbe",
    "title": "udv - sqlserver - dev.serilog.user",
    "tags": ["cew", "env: udv", "mst", "sealedsecret", "sqldb"],
    "version": 2,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T08:20:17Z",
    "updated_at": "2024-04-26T10:40:58Z",
    "additional_information": "dev.serilog.user"
  },
  {
    "id": "itvdhya7pybnpfbu56o76k3uei",
    "title": "udv - keycloak - admin",
    "tags": ["MST", "cew", "env: udv", "keycloak", "sealedsecret"],
    "version": 3,
    "vault": {
      "id": "lm2ln3xcz3ldbk4y7zwag467oe",
      "name": "mst-cew-preprod"
    },
    "category": "LOGIN",
    "last_edited_by": "AKTHBIZ5FZFKLH3CWMWYOW4CPA",
    "created_at": "2024-04-17T10:32:26Z",
    "updated_at": "2024-04-18T09:21:55Z",
    "additional_information": "admin"
  }
]'| ConvertFrom-Json