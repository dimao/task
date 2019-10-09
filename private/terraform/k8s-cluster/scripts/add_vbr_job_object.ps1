param(
    [string]$vm_name,
    [string]$job_name,
    [string]$veeam_host,
    [string]$veeam_user,
    [string]$veeam_password,
    [string]$remove_vm
)
Add-PSSnapin VeeamPSSnapin
Connect-VBRServer -Server $veeam_host -User $veeam_user -Password $veeam_password

if ($remove_vm -eq $true) {
    Get-VBRJob -Name $job_name | Get-VBRJobObject -Name $vm_name | Remove-VBRJobObject
}
else {
    Find-VBRViEntity -Name $vm_name | Add-VBRViJobObject -Job $job_name
}