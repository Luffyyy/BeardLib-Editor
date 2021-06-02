pushd ..\..

rem Alpha
rem CubeMapGen -exportFilename:CUBE_A.dds -exportPixelFormat:A8R8G8B8 -exportMipChain -exportCubeDDS -filterTech:AngularGaussian -baseFilterAngle:1 -initialMipFilterAngle:10.4 -perLevelMipFilterScale:1.24 -edgeFixupWidth:5 -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit
CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -filterTech:AngularGaussian -baseFilterAngle:12 -initialMipFilterAngle:0 -perLevelMipFilterScale:0 -edgeFixupTech:HermiteAverage -edgeFixupWidth:3 -solidAngleWeighting -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

rem RGB
rem CubeMapGen -exportFilename:CUBE_RGB.dds -exportPixelFormat:A8R8G8B8 -exportMipChain -exportCubeDDS -filterTech:AngularGaussian -baseFilterAngle:1 -initialMipFilterAngle:10.4 -perLevelMipFilterScale:1.24 -edgeFixupWidth:5 -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit
CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -filterTech:AngularGaussian -baseFilterAngle:25 -initialMipFilterAngle:0 -perLevelMipFilterScale:0 -edgeFixupTech:HermiteAverage -edgeFixupWidth:3 -solidAngleWeighting -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

rem hmm?
rem CubeMapGen -exportFilename:%7 -exportPixelFormat:A8R8G8B8 -exportMipChain -exportCubeDDS -filterTech:AngularGaussian -baseFilterAngle:1 -initialMipFilterAngle:10.4 -perLevelMipFilterScale:1.24 -edgeFixupWidth:5 -exportSize:256 -importFaceXPos:%1 -importFaceXNeg:%2 -importFaceYPos:%3 -importFaceYNeg:%4 -importFaceZPos:%5 -importFaceZNeg:%6 -exportCubeDDS -exit

ImgMerger CUBE_RGB.dds CUBE_A.dds CUBE_OUT_00.dds CUBE_OUT_01.dds CUBE_OUT_02.dds
stitch CUBE_OUT


copy CUBE_OUT.dds %7

del CUBE_OUT_00.dds /Q
del CUBE_OUT_01.dds /Q
del CUBE_OUT_02.dds /Q
del CUBE_OUT.dds /Q
del CUBE_A.dds /Q
del CUBE_RGB.dds /Q

popd

