# ASSIGN PROPER VALUES FOR THE FIELDS BELOW. PLACE EACH VALUE INSIDE THE QUOTATION MARKS

$clientAdminId = "your admin app's client id"           # Client ID of the admin app registered in Azure Portal. IMG 1
$clientSecret = "your admin app's secret value"         # Secret value for a generated secret for the admin app registered in Azure Portal. IMG 2
$clientChamId = "your chameleon app's client id"        # Client ID of the chameleon app registered in Azure Portal. IMG 3
$tenantId = "your tenant id"                            # Your tenant ID in app registrations in Azure Portal. IMG 4

$urlKey = "your URL key"                                # Is part of the url of the sharepoint site. For this URL:           https://12example34.sharepoint.com/sites/mySite
                                                        # ------------------------------------------ This would be the key:  //12example34.sharepoint.com/

$siteName = "your target site name"                     # Is the name of your site. For this URL:                   https://12example34.sharepoint.com/sites/mySite
                                                        # ------------------------- This would be the site's name:  mySite

# SCRIPT LOGIC BELOW
try {
    # Set the Graph API endpoint for SharePoint sites
    $graphUrl = "https://graph.microsoft.com/v1.0/sites/$urlKey`:/sites/$siteName"

    # Construct the authentication token request body
    $authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $authBody = @{
        grant_type    = "client_credentials"
        client_id     = $clientAdminId
        client_secret = $clientSecret
        scope         = "https://graph.microsoft.com/.default"
    }

    # Make the authentication token request
    $authResponse = Invoke-RestMethod -Method Post -Uri $authUrl -Body $authBody

    # Get the access token from the authentication token response
    $accessToken = $authResponse.access_token

    Write-Output "Access token retrieved"

    # Create the header for the Graph API request
    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    # Make the Graph API request to get the site ID
    $siteResponse = Invoke-RestMethod -Method Get -Uri $graphUrl -Headers $headers

    # Get the ID of the site from the Graph API response
    $siteId = $siteResponse.id

    Write-Output "Site ID: $siteId"

    # Set the Graph API endpoint to give permissions to Chameleon APP
    $permUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/permissions"

    $permHeaders = $headers = @{
        Authorization = "$accessToken" 
    }

    # Construct the authentication token request body
    $permBody = @{
      roles = @("write", "read", "delete", "edit")
      grantedToIdentities = @(
        @{
          application = @{
            id = $clientChamId
            displayName = "chameleon"
          }
        }
      )
    }|ConvertTo-Json -Depth 10
    Write-Output "$permBody"

    # Make the permissions request
    $permResponse = Invoke-RestMethod -Method Post -Uri $permUrl -Body $permBody -Headers $permHeaders -ContentType "application/json"

    Write-Output "$permResponse"
    Write-Output "Permissions granted succesfully"
}
catch {
  Write-Host "An error occurred:"
  Write-Host $_
}

# Stop the script from closing the console
Read-Host "Press Enter to exit"