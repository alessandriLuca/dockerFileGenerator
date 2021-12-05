#!/bin/bash 
if [ $# -eq 0 ]
  then
    echo "You need to provide a docker tag and a dockerFolder name, for example ./buildMe.sh dockertest tempFolder"
    exit
fi

if [ $# -eq 1 ]
  then
    echo "You need to provide a docker tag and a dockerFolder name, for example ./buildMe.sh dockertest tempFolder"
    exit
fi

mv Dockerfile_1 Dockerfile
 docker rmi -f $1
 docker build . -t $1
cp configurationFile.R ./R-3.6.3_toBeInstalled/libraryInstall.R
 docker run -itv $(pwd)/R-3.6.3_toBeInstalled:/scratch $1 /scratch/1_libraryInstall.sh
mv Dockerfile Dockerfile_1
mv Dockerfile_2 Dockerfile
 docker build . -t $1
mv Dockerfile Dockerfile_2
mkdir $2 
cp Dockerfile_2 ./$2/Dockerfile
cp -r ./R-3.6.3 ./$2/R-3.6.3
mkdir ./$2/R-3.6.3_toBeInstalled
cp ./R-3.6.3_toBeInstalled/*.7z* ./$2/R-3.6.3_toBeInstalled/
cp ./pcre2-10.37.tar.gz ./$2/pcre2-10.37.tar.gz
cp -r ./p7zip_16.02 ./$2/
cp ./R-3.6.3_toBeInstalled/listForDockerfile.sh ./$2/R-3.6.3_toBeInstalled/listForDockerfile.sh
 docker rmi -f $1
rm -r ./R-3.6.3_toBeInstalled/packages
rm ./R-3.6.3_toBeInstalled/libraryInstall.R
rm ./R-3.6.3_toBeInstalled/nohup.out
rm ./R-3.6.3_toBeInstalled/*.7z.*
rm ./R-3.6.3_toBeInstalled/listForDockerfile.sh
rm ./R-3.6.3_toBeInstalled/toDownload.txt
rm ./R-3.6.3_toBeInstalled/toInstall.txt