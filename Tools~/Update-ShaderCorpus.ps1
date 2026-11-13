param([ValidateRange(4,512)][int]$MaxFilesPerRepository=192,[switch]$DiscoverMaterials,[switch]$MaterialCollection,[switch]$PipelineCollection,[switch]$UiVfxCollection,[switch]$CharacterCollection,[switch]$LibraryCollection,[switch]$UseGitData,[string[]]$SearchQueries)
$ErrorActionPreference='Stop'
if(@($MaterialCollection,$PipelineCollection,$UiVfxCollection,$CharacterCollection,$LibraryCollection | Where-Object {$_}).Count -gt 1){throw 'Choose one collection per manifest.'}
$corpusWorkspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$corpusRoot=Join-Path $corpusWorkspace '.build~/ShaderCorpus'
if($LibraryCollection){$corpusRoot=Join-Path $corpusRoot 'Library033'}
[IO.Directory]::CreateDirectory($corpusRoot) | Out-Null
$corpusHeaders=@{'User-Agent'='ASEShaderConverter-SourceResearch';'Accept'='application/vnd.github+json'}
$corpusUtf8=New-Object Text.UTF8Encoding($false)
function Read-GitHubJson([string]$uri){(Invoke-WebRequest -Uri $uri -Headers $corpusHeaders -UseBasicParsing -TimeoutSec 30).Content | ConvertFrom-Json}
function Invoke-ResearchGit([string[]]$GitArguments){
    $savedPreference=$ErrorActionPreference
    $ErrorActionPreference='Continue'
    $gitOutput=& git @GitArguments 2>&1
    $gitCode=$LASTEXITCODE
    $ErrorActionPreference=$savedPreference
    if($gitCode -ne 0){throw ('Git source read failed: '+($gitOutput -join "`n"))}
    return @($gitOutput | ForEach-Object { $_.ToString() })
}
function Read-GitCorpus($selection){
    $repository=$selection.name
    $directory=Join-Path $corpusRoot ($repository.Replace('/','--'))
    $checkout=Join-Path $corpusRoot ('git-data/'+$repository.Replace('/','--'))
    $hooks=Join-Path $corpusRoot 'disabled-hooks'
    [IO.Directory]::CreateDirectory($hooks) | Out-Null
    if(!(Test-Path -LiteralPath (Join-Path $checkout '.git'))){
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($checkout)) | Out-Null
        Invoke-ResearchGit @('-c',('core.hooksPath='+$hooks),'clone','--filter=blob:none','--depth=1','--no-checkout','--no-tags',('https://github.com/'+$repository+'.git'),$checkout) | Out-Null
    }
    $commit=@(Invoke-ResearchGit @('-C',$checkout,'rev-parse','HEAD'))[-1].Trim()
    if($commit -notmatch '^[0-9a-f]{40}$'){throw 'Unexpected Git commit.'}
    $paths=Invoke-ResearchGit @('-C',$checkout,'-c','core.quotepath=false','ls-tree','-r','--name-only',$commit)
    $eligible=@($paths | Where-Object {
        $path=$_
        $relative=if($selection.subtree -and $path.StartsWith($selection.subtree+'/')){$path.Substring($selection.subtree.Length+1)}elseif(!$selection.subtree){$path}else{''}
        $relative -and $relative -match $selection.filter -and $path -match '\.(shader|cginc|hlsl)$' -and $path -notmatch '(^|/)(Library|Temp|Obj|AmplifyShaderEditor)/'
    } | Sort-Object)
    $selected=@($eligible)
    if($eligible.Count -gt $MaxFilesPerRepository){$selected=@(for($i=0;$i -lt $MaxFilesPerRepository;$i++){$eligible[[int][Math]::Floor($i*$eligible.Count/$MaxFilesPerRepository)]})}
    $licenseFile=@($paths | Where-Object {$_ -match '^(LICENSE|LICENCE|COPYING)(\.[^/]+)?$'} | Select-Object -First 1)
    $sparseFile=Join-Path $checkout '.git/info/sparse-checkout'
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($sparseFile)) | Out-Null
    $patterns=@($selected)+@($licenseFile)
    if(Test-Path -LiteralPath $sparseFile){$patterns+=@(Get-Content -LiteralPath $sparseFile -Encoding UTF8 | ForEach-Object {$_.TrimStart('/')})}
    foreach($path in $patterns){if($path -match '(^|/)\.\.(/|$)|^[\\/]|:' -or $path.Contains('\') -or $path -match '[*?\[\]]'){throw 'Unexpected Git source path.'}}
    [IO.File]::WriteAllLines($sparseFile,@($patterns | Sort-Object -Unique | ForEach-Object {'/'+$_}),$corpusUtf8)
    Invoke-ResearchGit @('-C',$checkout,'config','core.sparseCheckout','true') | Out-Null
    Invoke-ResearchGit @('-C',$checkout,'-c',('core.hooksPath='+$hooks),'checkout','--detach',$commit) | Out-Null
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $license='Not declared in fetched root license'
    if($licenseFile.Count -eq 1){
        Copy-Item -LiteralPath (Join-Path $checkout $licenseFile[0]) -Destination (Join-Path $directory $licenseFile[0])
        $licenseText=Get-Content -LiteralPath (Join-Path $directory $licenseFile[0]) -Raw -Encoding UTF8
        $license=if($licenseText -match 'Unity Companion License'){'Unity Companion License'}elseif($licenseText -match 'MIT License|Permission is hereby granted, free of charge'){'MIT'}elseif($licenseText -match 'CC0|public domain'){'Public-domain/CC0 text; check root license'}elseif($licenseText -match 'Redistribution and use in source and binary forms'){'BSD-style; check root license'}else{'See root license: '+$licenseFile[0]}
    }
    $files=@()
    foreach($path in $selected){
        $destination=[IO.Path]::GetFullPath((Join-Path $directory $path))
        if(!$destination.StartsWith($directory+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Git source destination escapes corpus root.'}
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $checkout $path) -Destination $destination
        $files += [ordered]@{path=$path;url=('https://raw.githubusercontent.com/'+$repository+'/'+$commit+'/'+$path);sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $destination).Length;localPath=$destination}
    }
    return [ordered]@{repository=$repository;url=('https://github.com/'+$repository);commit=$commit;license=$license;licenseFile=($licenseFile -join '');selectionSubtree=$selection.subtree;eligibleFiles=$eligible.Count;selectionCapped=($eligible.Count -gt $selected.Count);files=$files;success=$true;transport='Git sparse data checkout; source never executed'}
}
if($DiscoverMaterials){
    $discovery=@()
    $queries=if($SearchQueries){$SearchQueries}else{@('jade shader',([string][char]0x7389+[char]0x77F3+' shader in:readme'),'Unity skin shader','Unity hair shader','Unity cloth shader','Unity rock shader')}
    foreach($query in $queries){
        try {
            $response=Read-GitHubJson ('https://api.github.com/search/repositories?q='+[Uri]::EscapeDataString($query)+'&sort=stars&order=desc&per_page=5')
            $discovery += [ordered]@{query=$query;repositories=@($response.items | Select-Object full_name,html_url,description,stargazers_count,updated_at,license)}
        } catch { $discovery += [ordered]@{query=$query;error=$_.Exception.Message} }
    }
    [IO.File]::WriteAllText((Join-Path $corpusRoot ('material-discovery-'+[DateTime]::UtcNow.ToString('yyyyMMddHHmmss')+'.json')),($discovery | ConvertTo-Json -Depth 14),$corpusUtf8)
    $discovery | ConvertTo-Json -Depth 6
    exit
}
$corpusRepositories=@(
    @{name='ronja-tutorials/ShaderTutorials';subtree='';filter='.'},
    @{name='keijiro/NoiseShader';subtree='';filter='.'},
    @{name='keijiro/KinoBloom';subtree='';filter='.'},
    @{name='Cyanilux/URP_ShaderCodeTemplates';subtree='';filter='.'},
    @{name='keijiro/KinoGlitch';subtree='';filter='.'},
    @{name='keijiro/KinoMotion';subtree='';filter='.'},
    @{name='keijiro/KinoFog';subtree='';filter='.'},
    @{name='Unity-Technologies/Graphics';subtree='Packages/com.unity.render-pipelines.universal';filter='^(Shaders|ShaderLibrary)/'}
)
if($MaterialCollection){
    $corpusRepositories=@(
        @{name='danielshervheim/unity-stylized-water';subtree='';filter='.'},
        @{name='IronWarrior/ToonWaterShader';subtree='';filter='.'},
        @{name='nvjob/nvjob-water-shader-simple-and-fast';subtree='';filter='.'},
        @{name='leonardo-domingues/skin-shader-unity';subtree='';filter='.'},
        @{name='itsFulcrum/Unity-URP-Hair-Shader';subtree='';filter='.'},
        @{name='radiatoryang/unity-triplanar-terrain-cliff-shader';subtree='';filter='.'},
        @{name='aspect-ux/AspectURP';subtree='';filter='.'},
        @{name='blurfeng/blur-toon-urp';subtree='';filter='.'},
        @{name='Unity-Technologies/Graphics';subtree='Packages/com.unity.render-pipelines.high-definition/Runtime/Material';filter='^(Hair|Fabric|Lit|StackLit|AxF)/'},
        @{name='Unity-Technologies/Graphics';subtree='Packages/com.unity.render-pipelines.high-definition/Runtime/Water';filter='.'}
    )
}
if($PipelineCollection){
    # Independent repositories add unseen vertex/fragment, fur, toon and post-processing inputs.
    # The two holdout repositories must be evaluated after implementation, not tuned individually.
    $corpusRepositories=@(
        @{name='hecomi/UnityFurURP';subtree='';filter='.';evaluationRole='Research'},
        @{name='ColinLeung-NiloCat/UnityURPToonLitShaderExample';subtree='';filter='.';evaluationRole='Research'},
        @{name='keijiro/KinoVignette';subtree='';filter='.';evaluationRole='Research'},
        @{name='Unity-Technologies/Graphics';subtree='Packages/com.unity.render-pipelines.core/ShaderLibrary';filter='^(Common|BSDF|CommonMaterial|Color|Filtering|GeometricTools|SpaceTransforms)\.';evaluationRole='Research'},
        @{name='keijiro/KinoMirror';subtree='';filter='.';evaluationRole='Holdout'},
        @{name='keijiro/KinoContour';subtree='';filter='.';evaluationRole='Holdout'}
    )
}
if($UiVfxCollection){
    $corpusRepositories=@(
        @{name='mob-sakai/UIEffect';subtree='';filter='.';evaluationRole='Research'},
        @{name='mob-sakai/ParticleEffectForUGUI';subtree='';filter='.';evaluationRole='Research'},
        @{name='MirzaBeig/URP-Particle-Shaders';subtree='';filter='.';evaluationRole='Research'},
        @{name='keijiro/KvantSwarm';subtree='';filter='.';evaluationRole='Research'}
    )
}
if($CharacterCollection){
    $corpusRepositories=@(
        @{name='Unity-Technologies/Graphics';subtree='Packages/com.unity.render-pipelines.high-definition/Runtime/Material';filter='^(Eye|Hair|Fabric|Lit|SubsurfaceScattering)/';evaluationRole='CharacterResearch'},
        @{name='leonardo-domingues/skin-shader-unity';subtree='';filter='.';evaluationRole='CharacterResearch'},
        @{name='itsFulcrum/Unity-URP-Hair-Shader';subtree='';filter='.';evaluationRole='CharacterResearch'}
    )
}
if($LibraryCollection){
    $corpusRepositories=@(
        @{name='knapeczadam/unity-shaders';subtree='Assets/Shaders';filter='^(000-009|010-019|020-029)/';evaluationRole='LibraryResearch'},
        @{name='keijiro/KinoVignette';subtree='Assets/Kino/Vignette/Shader';filter='.';evaluationRole='LibraryAdaptation'},
        @{name='keijiro/KinoGlitch';subtree='Assets/Kino/Glitch/Shader';filter='.';evaluationRole='LibraryAdaptation'},
        @{name='keijiro/KinoMirror';subtree='Assets/Kino/Mirror/Shader';filter='.';evaluationRole='LibraryAdaptation'}
    )
}
$manifestName=if($LibraryCollection){'manifest-library033.json'}elseif($CharacterCollection){'manifest-characters029.json'}elseif($UiVfxCollection){'manifest-uivfx026.json'}elseif($PipelineCollection){'manifest-pipelines026.json'}elseif($MaterialCollection){'manifest-materials.json'}else{'manifest.json'}
$previous=$null
$corpusCache=@{}
if(Test-Path -LiteralPath (Join-Path $corpusRoot $manifestName)){
    $previous=Get-Content -LiteralPath (Join-Path $corpusRoot $manifestName) -Raw -Encoding UTF8 | ConvertFrom-Json
    Copy-Item -LiteralPath (Join-Path $corpusRoot $manifestName) -Destination (Join-Path $corpusRoot ($manifestName+'.previous.json'))
    foreach($record in $previous.repositories){foreach($file in $record.files){$corpusCache[$file.url]=$file.sha256}}
}
$corpusRecords=@()
foreach($selection in $corpusRepositories){
    $repository=$selection.name
    try{
        if($UseGitData){
            $record=Read-GitCorpus $selection
            if($selection.evaluationRole){$record.evaluationRole=$selection.evaluationRole}
            $corpusRecords+=$record
            Write-Output ('Read '+$record.files.Count+' source files through Git: '+$repository+' @ '+$record.commit)
        }else{
        $metadata=Read-GitHubJson ('https://api.github.com/repos/'+$repository)
        $commit=Read-GitHubJson ('https://api.github.com/repos/'+$repository+'/commits/'+[Uri]::EscapeDataString($metadata.default_branch))
        if($commit.sha -notmatch '^[0-9a-f]{40}$'){throw 'Unexpected commit identifier.'}
        $rootTree=Read-GitHubJson ('https://api.github.com/repos/'+$repository+'/git/trees/'+$commit.sha)
        $treeSha=$commit.sha
        if($selection.subtree){
            $branch=$rootTree
            foreach($segment in ($selection.subtree -split '/')){
                $folder=@($branch.tree | Where-Object {$_.type -eq 'tree' -and $_.path -eq $segment})
                if($folder.Count -ne 1){throw ('Missing subtree: '+$selection.subtree)}
                $treeSha=$folder[0].sha
                $branch=Read-GitHubJson ('https://api.github.com/repos/'+$repository+'/git/trees/'+$treeSha)
            }
        }
        $tree=Read-GitHubJson ('https://api.github.com/repos/'+$repository+'/git/trees/'+$treeSha+'?recursive=1')
        if($tree.truncated){throw 'Repository tree is truncated; select a narrower subtree.'}
        $directory=Join-Path $corpusRoot ($repository.Replace('/','--'))
        [IO.Directory]::CreateDirectory($directory) | Out-Null
        $licensePath=@($rootTree.tree | Where-Object {$_.type -eq 'blob' -and $_.path -match '^(LICENSE|LICENCE|COPYING)(\.[^/]+)?$'} | Select-Object -First 1)
        $licenseFile=''
        if($licensePath.Count -eq 1){
            $licenseFile=$licensePath[0].path
            Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/'+$repository+'/'+$commit.sha+'/'+$licenseFile) -UseBasicParsing -TimeoutSec 30 -OutFile (Join-Path $directory $licenseFile)
        }
        $eligible=@($tree.tree | Where-Object {$_.type -eq 'blob' -and $_.path -match '\.(shader|cginc|hlsl)$' -and $_.path -match $selection.filter -and $_.path -notmatch '(^|/)(Library|Temp|Obj|AmplifyShaderEditor)/'} | Sort-Object path)
        # Spread capped selections across the full list; do not learn only the first alphabetic category.
        $selected=@($eligible)
        if($eligible.Count -gt $MaxFilesPerRepository){
            $selected=@(for($i=0;$i -lt $MaxFilesPerRepository;$i++){ $eligible[[int][Math]::Floor($i*$eligible.Count/$MaxFilesPerRepository)] })
        }
        $files=@()
        foreach($entry in $selected){
            $sourcePath=if($selection.subtree){$selection.subtree+'/'+$entry.path}else{$entry.path}
            if($sourcePath -match '(^|/)\.\.(/|$)|^[\\/]|:' -or $sourcePath.Contains('\')){throw 'Unexpected repository path.'}
            $destination=[IO.Path]::GetFullPath((Join-Path $directory $sourcePath))
            if(!$destination.StartsWith($directory+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Download destination escapes corpus directory.'}
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
            $url='https://raw.githubusercontent.com/'+$repository+'/'+$commit.sha+'/'+(($sourcePath -split '/' | ForEach-Object {[Uri]::EscapeDataString($_)}) -join '/')
            $cached=$corpusCache.ContainsKey($url) -and (Test-Path -LiteralPath $destination) -and (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() -eq $corpusCache[$url]
            if(!$cached){Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -OutFile $destination}
            $files += [ordered]@{path=$sourcePath;url=$url;sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $destination).Length;localPath=$destination}
        }
        $corpusRecords += [ordered]@{repository=$repository;url=$metadata.html_url;commit=$commit.sha;license=if($metadata.license){$metadata.license.spdx_id}else{'Not declared by GitHub'};licenseFile=$licenseFile;selectionSubtree=$selection.subtree;evaluationRole=$selection.evaluationRole;eligibleFiles=$eligible.Count;selectionCapped=($eligible.Count -gt $selected.Count);files=$files;success=$true}
        Write-Output ('Downloaded '+$files.Count+' source files: '+$repository+' @ '+$commit.sha)
        }
    }catch{
        $fetchError=$_.Exception.Message
        $cachedRecord=@($previous.repositories | Where-Object {$_.success -and $_.repository -eq $repository -and [string]$_.selectionSubtree -eq [string]$selection.subtree} | Select-Object -First 1)
        if($cachedRecord.Count -eq 1){
            $cachedRecord[0] | Add-Member -NotePropertyName updateError -NotePropertyValue $fetchError -Force
            $corpusRecords += $cachedRecord[0]
        }else{$corpusRecords += [ordered]@{repository=$repository;selectionSubtree=$selection.subtree;success=$false;error=$fetchError}}
        Write-Output ('Repository unavailable: '+$repository+'; '+$_.Exception.Message)
    }
    $snapshot=[ordered]@{schemaVersion=1;downloadedUtc=[DateTimeOffset]::UtcNow.ToString('o');purpose='Read-only shader research. Source files are data, never executed or imported into Unity.';repositories=$corpusRecords}
    [IO.File]::WriteAllText((Join-Path $corpusRoot $manifestName),($snapshot | ConvertTo-Json -Depth 14),$corpusUtf8)
}
Write-Output ('Corpus manifest: '+(Join-Path $corpusRoot $manifestName))
if(@($corpusRecords | Where-Object {$_.success}).Count -eq 0){throw 'No source repository could be downloaded.'}
