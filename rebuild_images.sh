# PREREQUESITE: Built image for MZBench Publisher
cd ./mzbench-docker-deployment
chmod +x build.sh
./build.sh
cd ..

cd ./jorammq-deployment
chmod +x build.sh
./build.sh
cd ..

cd ./border/containernet/BORDER/clients/alpine_container/
chmod +x build.sh
./build.sh
cd /home/randerer/