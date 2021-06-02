@ECHO OFF
pushd ..\..
ECHO GENERATING

rem CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -exportCubeDDS -filterTech:AngularGaussian -baseFilterAngle:1 -initialMipFilterAngle:10.4 -perLevelMipFilterScale:1.24 -edgeFixupWidth:5 -exportSize:256 -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

rem CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -filterTech:AngularGaussian -baseFilterAngle:3 -initialMipFilterAngle:1 -perLevelMipFilterScale:1 -edgeFixupTech:HermiteAverage -edgeFixupWidth:3 -solidAngleWeighting -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

"%~dp0\CubeMapGen.exe" -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -numFilterThreads:2 -exportMipChain -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

popd
