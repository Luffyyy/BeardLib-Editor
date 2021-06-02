@ECHO OFF

pushd ..\..

ECHO GENERATING


rem CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -filterTech:AngularGaussian -baseFilterAngle:10 -initialMipFilterAngle:1 -perLevelMipFilterScale:1 -edgeFixupTech:HermiteAverage -edgeFixupWidth:5 -solidAngleWeighting -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

rem CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit


rem CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportSize:64 -exportMipChain -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

"%~dp0\CubeMapGen.exe" -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -filterTech:AngularGaussian -baseFilterAngle:10 -initialMipFilterAngle:0 -perLevelMipFilterScale:0 -edgeFixupTech:HermiteAverage -edgeFixupWidth:1 -solidAngleWeighting -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit


popd
