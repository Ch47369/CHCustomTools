$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$previewRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$previewFolder=Join-Path $previewRoot 'Documentation~/Evidence/Showcase035'
$previewCanvas=New-Object Drawing.Bitmap(940,1010)
$previewGraphics=[Drawing.Graphics]::FromImage($previewCanvas)
$previewGraphics.Clear([Drawing.Color]::FromArgb(20,23,30))
$previewGraphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$previewTitle=New-Object Drawing.Font('Segoe UI',18,[Drawing.FontStyle]::Bold)
$previewText=New-Object Drawing.Font('Segoe UI',12)
$previewGraphics.DrawString('Layered Parallax Glitter - ASE / Unity renders',$previewTitle,[Drawing.Brushes]::White,20,12)
$previewGraphics.DrawString('One source / three pipelines / three material color presets',$previewText,[Drawing.Brushes]::LightGray,20,47)
$previewPipelines=@('BuiltIn','URP','HDRP');$previewPresets=@('BlueCyan','GoldOrange','Purple')
for($previewRow=0;$previewRow -lt 3;$previewRow++){
    for($previewColumn=0;$previewColumn -lt 3;$previewColumn++){
        $previewX=20+$previewColumn*305;$previewY=90+$previewRow*300
        $previewPath=Join-Path $previewFolder ($previewPipelines[$previewRow]+'/Scene/'+$previewPresets[$previewColumn]+'.png')
        $previewImage=[Drawing.Image]::FromFile($previewPath)
        try{
            $previewGraphics.DrawString(($previewPipelines[$previewRow]+' / '+$previewPresets[$previewColumn]),$previewText,[Drawing.Brushes]::LightGray,$previewX,$previewY)
            $previewTarget=New-Object Drawing.Rectangle($previewX,($previewY+26),285,260)
            # Crop surrounding empty background; material pixels are otherwise unchanged.
            $previewGraphics.DrawImage($previewImage,$previewTarget,85,35,310,285,[Drawing.GraphicsUnit]::Pixel)
        }finally{$previewImage.Dispose()}
    }
}
$previewGraphics.DrawString('Native shader output; original procedural sample textures. PC / high complexity.',$previewText,[Drawing.Brushes]::LightGray,20,990)
$previewCanvas.Save((Join-Path $previewFolder 'preview.png'),[Drawing.Imaging.ImageFormat]::Png)
$previewGraphics.Dispose();$previewCanvas.Dispose();$previewTitle.Dispose();$previewText.Dispose()
Write-Output (Join-Path $previewFolder 'preview.png')
