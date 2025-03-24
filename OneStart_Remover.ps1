# OneStart removal script (updated to remove all OneStart tasks)

# Stop OneStart processes
$valid_path = "C:\Users\*\AppData\Local\OneStart.ai\*"
$process_names = @("OneStart")
foreach ($proc in $process_names){
    $OL_processes = Get-Process | Where-Object { $_.Name -like $proc }
    if ($OL_processes.Count -eq 0){
        Write-Output "No $proc processes were found."
    } else {
        write-output "Stopping processes: $OL_processes"
        foreach ($process in $OL_processes){
            $path = $process.Path
            if ($path -like $valid_path){
                Stop-Process $process -Force
                Write-Output "$proc process stopped."
            }
        }
    }
}

Start-Sleep -Seconds 2

# Remove OneStart directories
$file_paths = @("\AppData\Roaming\OneStart\", "\AppData\Local\OneStart.ai\")
foreach ($folder in (Get-ChildItem C:\Users)) {
    foreach ($fpath in $file_paths) {
        $path = Join-Path -Path $folder.FullName -ChildPath $fpath
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $path)) {
                Write-Output "$path deleted."
            }
        }
    }
}

# Remove registry entries
$reg_paths = @("\software\OneStart.ai")
foreach ($registry_hive in (get-childitem registry::hkey_users)) {
    foreach ($regpath in $reg_paths){
        $path = $registry_hive.pspath + $regpath
        if (test-path $path) {
            Remove-item -Path $path -Recurse -Force
            write-output "Registry key $path removed."
        }
    }
}

# Remove registry startup entries
$reg_properties = @("OneStartBar", "OneStartBarUpdate", "OneStartUpdate")
foreach($registry_hive in (get-childitem registry::hkey_users)){
    foreach ($property in $reg_properties){
        $path = $registry_hive.pspath + "\software\microsoft\windows\currentversion\run"
        if (test-path $path){
            $reg_key = Get-Item $path
            $prop_value = $reg_key.GetValueNames() | Where-Object { $_ -like $property }
            if ($prop_value){
                Remove-ItemProperty $path $prop_value
                Write-output "Registry property $path\$prop_value removed."
            }
        }
    }
}

# Remove **all** scheduled tasks related to OneStart
$all_tasks = Get-ScheduledTask | Where-Object { $_.TaskName -match "OneStart" }
if ($all_tasks) {
    foreach ($task in $all_tasks) {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
        Write-Output "Scheduled task '$($task.TaskName)' removed."
    }
} else {
    Write-Output "No OneStart scheduled tasks found."
}

# Remove OneStart shortcut from Desktop
foreach ($folder in (Get-ChildItem C:\Users)) {
    $desktopPath = Join-Path -Path $folder.FullName -ChildPath "Desktop\OneStart.lnk"
    if (Test-Path $desktopPath) {
        Remove-Item -Path $desktopPath -Force -ErrorAction SilentlyContinue
        Write-Output "OneStart shortcut removed from Desktop."
    }
}

# Remove all OneStart-related files from Downloads folder
foreach ($folder in (Get-ChildItem C:\Users)) {
    $downloadsPath = Join-Path -Path $folder.FullName -ChildPath "Downloads"
    if (Test-Path $downloadsPath) {
        $oneStartFiles = Get-ChildItem -Path $downloadsPath -Filter "OneStart*" -File
        foreach ($file in $oneStartFiles) {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            Write-Output "Removed OneStart-related file: $($file.FullName) from Downloads folder."
        }
    }
}

Write-Output "OneStart removal completed!"
