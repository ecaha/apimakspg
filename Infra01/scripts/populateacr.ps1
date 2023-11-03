#sign in to azure, set right subscirption
$RegistryName = "sio2acr327"
$AksClusterName = "sio2-aks-cluster"

$ResourceGroup = (Get-AzContainerRegistry | Where-Object {$_.name -eq $RegistryName}).ResourceGroupName
$ControllerImage = "ingress-nginx/controller"
$ControllerTag = "v1.9.4"
$PatchImage = "ingress-nginx/kube-webhook-certgen"
$PatchTag = "v20231011-8b53cabe0"
$DefaultBackendImage ="defaultbackend-amd64"
$DefaultBackendTag ="1.5"


#Registry/image/tag

$images = @(
    ,@('registry.k8s.io',$ControllerImage,$ControllerTag)
    ,@('registry.k8s.io',$PatchImage,$PatchTag)
    ,@('registry.k8s.io',$DefaultBackendImage,$DefaultBackendTag)
    ,@('docker.io','yesinteractive/dadjokes','latest')
)


foreach ($image in $images)
{
    $registry = $image[0]
    $img = $image[1]
    $tag = $image[2]
    Write-Host "Importing from $registry image ${img}:${tag}"
    Import-AzContainerRegistryImage `
        -ResourceGroupName $ResourceGroup `
        -RegistryName $RegistryName `
        -SourceRegistryUri $registry `
        -SourceImage "${img}:${tag}" `
        -Mode Force
}