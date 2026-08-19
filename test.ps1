$Configuration="Release"

mkdir obj -Force | Out-Null
$de4dotExec="Release\net10.0\win-x64\de4dot.exe"

function Test($item)
{
	# tests\samples\inlining\inline_static_method_new.il
	$base = [System.IO.Path]::GetFileNameWithoutExtension($item)
	$dir = Split-Path $item
	mkdir -Force $dir | Out-Null
	ilasm /DLL /QUIET "$item" /OUTPUT=obj\$dir\$base.dll

	& $de4dotExec  obj\$dir\$base.dll -o obj\$dir\$base.cleaned.dll

	ildasm /NOBAR obj\$dir\$base.cleaned.dll /OUT=$dir\$base.cleaned.il
}

Test("tests\samples\inlining\inline_static_method.il")
Test("tests\samples\inlining\inline_static_generic_method.il")
Test("tests\samples\inlining\inline_static_method_br_target.il")
Test("tests\samples\inlining\inline_static_method_new.il")