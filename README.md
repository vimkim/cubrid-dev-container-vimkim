# CUBRID 빌드 및 실행 가이드

안녕하세요! CUBRID에 기여하고 싶으시거나 새로 합류하신 개발자분들을 위한 가이드입니다. 공식 문서에 빌드 방법이 간략하게 적혀 있지만, 세세한 부분을 보완하여 최신화된 가이드를 작성했습니다.

### 이 가이드가 유용한 이유

1. 현재 `install-build-requirements.md`에 적힌 스크립트는 `sudo su root` 이후 `root`로서 실행해야 하는데, 이 가이드는 일반 유저도 `sudo` 권한이 있다면 정상 빌드 가능합니다.
2. `set -e`를 추가해 스크립트 실패 시 바로 종료합니다.
3. && 로 연결되어 있는 명령어들을 여러 줄로 풀어서 가독성을 높였습니다.
4. 빌드에 성공 후 `csql`실행에 필요한 추가 설정 내용을 포함합니다. (예: `LD_LIBRARY_PATH`, `createdb` 등)

단순히 빌드에 성공하는 방법이 아니라, 소스코드에 기여하고 싶은 개발자가 빌드 성공 전후로 무엇을 해야 할지에 대한 전체적인 흐름과 구체적인 설명을 추가했습니다.

### 이 가이드의 목표

1. CentOS 7의 도커 이미지를 통해 개발 환경을 구성합니다.
2. 단순 빌드뿐만 아니라 디버깅용 빌드에도 성공합니다.
3. 빌드 이후 `demodb`를 생성하고, 독립 실행형 `csql`을 실행하고 테스트합니다.

---

### install-build-requirements.sh 준비

먼저 빈 디렉토리를 하나 만들고, 그 안에 `install-build-requirements.sh` 파일을 작성합니다.

```bash
#!/bin/bash

# 이 파일의 이름은 Dockerfile에서 사용되기 때문에 반드시 `install-build-requirements.sh`이어야 합니다.

# 명령어가 실패할 경우 오류 메시지를 출력하는 함수
trap 'echo "Error: Command failed at line $LINENO: $BASH_COMMAND"' ERR

set -e

sudo yum install -y centos-release-scl

# devtoolset-8 설치 (권장)
sudo yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++ devtoolset-8-make devtoolset-8-elfutils-libelf-devel devtoolset-8-systemtap-sdt-devel

source scl_source enable devtoolset-8 || true

sudo yum install -y ncurses-devel git which

# JDK 1.8 설치
sudo yum install -y java-1.8.0-openjdk-devel

# 빌드 도구 설치

# CMake 다운로드 및 추출
export CMAKE_VERSION=3.26.3
curl -L https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.tar.gz -o cmake-$CMAKE_VERSION-linux-x86_64.tar.gz
tar -xzvf cmake-$CMAKE_VERSION-linux-x86_64.tar.gz
sudo cp -fR cmake-$CMAKE_VERSION-linux-x86_64/* /usr
rm -rf cmake-$CMAKE_VERSION-linux-x86_64 cmake-$CMAKE_VERSION-linux-x86_64.tar.gz

# Ninja 다운로드 및 추출
export NINJA_VERSION=1.11.1
curl -L https://github.com/ninja-build/ninja/archive/refs/tags/v$NINJA_VERSION.tar.gz -o ninja-$NINJA_VERSION.tar.gz
tar -xzvf ninja-$NINJA_VERSION.tar.gz
cd ninja-$NINJA_VERSION
cmake -Bbuild-cmake
cmake --build build-cmake
sudo mv build-cmake/ninja /usr/bin/ninja
cd ..
rm -rf ninja-$NINJA_VERSION ninja-$NINJA_VERSION.tar.gz

sudo yum install -y ant libtool libtool-ltdl autoconf automake rpm-build
sudo yum install -y flex

# Bison 다운로드 및 추출
export BISON_VERSION=3.0.5
curl -L https://ftp.gnu.org/gnu/bison/bison-$BISON_VERSION.tar.gz -o bison-$BISON_VERSION.tar.gz
tar -xzvf bison-$BISON_VERSION.tar.gz
cd bison-$BISON_VERSION
sudo ./configure --prefix=/usr
sudo make all install
cd ..
sudo rm -rf bison-$BISON_VERSION bison-$BISON_VERSION.tar.gz
```

이 파일은 CUBRID 공식 GitHub 레포지토리에 있는 `install_build_requirements.md`를 참고하여 업데이트한 내용입니다.

참고: https://github.com/CUBRID/cubrid/blob/develop/docs/install_build_requirements.md

---

### .cubrid_env.sh 준비

같은 디렉토리 안에서 `.cubrid_env.sh` 파일도 만들어줍니다. 이 파일은 CUBRID 빌드 및 `csql` 실행에 필요한 환경 변수들과 `PATH` 변수 업데이트 등의 내용을 담고 있습니다. 이 파일 역시 Dockerfile에서 사용됩니다.

```sh
#!/bin/bash

# 이 파일의 이름은 Dockerfile에서 사용되기 때문에 반드시 `.cubrid_env.sh`이어야 합니다.

# devtoolset-8 활성화
source scl_source enable devtoolset-8

# make 병렬 작업 수 설정
export MAKEFLAGS="-j $(nproc)"

# JAVA_HOME 자동 설정
JAVA_PATH=$(command -v java)
if [ -n "$JAVA_PATH" ]; then
    JAVA_PATH=$(readlink -f "$JAVA_PATH")
    JAVA_HOME=$(dirname "$(dirname "$(dirname "$JAVA_PATH")")")
    export JAVA_HOME
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME is set to $JAVA_HOME"
else
    echo "Java not found in PATH. Please install Java or ensure it is in your PATH."
fi

# CUBRID 환경 변수 설정
export CUBRID="$HOME/CUBRID"
export CUBRID_DATABASES="$CUBRID/databases"
export LD_LIBRARY_PATH="$CUBRID/lib:$CUBRID/cci/lib:$LD_LIBRARY_PATH"

export PATH="$CUBRID/bin:$PATH"

# 설정 확인
echo "CUBRID environment set up successfully."
echo "CUBRID=$CUBRID"
echo "CUBRID_DATABASES=$CUBRID_DATABASES"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
```

이 파일은 주영진님의 GitHub 레포지토리에 있는 `.custom_profile`을 참고하여 업데이트한 내용입니다. 해당 파일은 큐브리드 내 개발 서버를 구성하는데에 실제로 유용하게 사용 중입니다.

참고: https://github.com/youngjinj/cubrid-dev-containers/blob/main/cubrid/.custom_profile

> Docker를 사용하지 않고 CentOS7에 직접 설치하실 분들은 수동으로 .bashrc 혹은 그에 상응하는 파일들 (.zshrc, .bash_profile 등)에 추가하여 소싱해주시면 됩니다.

```sh
echo 'source $HOME/.cubrid_env.sh' >> .bashrc
```

---

### Dockerfile 준비

같은 디렉토리 안에서 `Dockerfile`을 작성합니다.

```dockerfile
# Dockerfile

FROM centos:7

# 베이스 이미지 업데이트 및 sudo 설치
RUN yum -y update && \
    yum install -y sudo && \
    yum clean all

RUN yum install -y vim

ENV USER=dhkimc

# dhkim 사용자 추가 및 sudo 권한 부여
RUN adduser $USER && \
    usermod -aG wheel $USER && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 작업 디렉토리 설정
WORKDIR /home/$USER

# Copy scripts and ensure they have execute permissions
COPY --chown=$USER:$USER ./install-build-requirements.sh ./install-build-requirements.sh
COPY --chown=$USER:$USER ./.cubrid_env.sh ./.cubrid_env.sh

# Make sure the scripts have execute permissions
RUN chmod +x ./install-build-requirements.sh ./install-build-requirements.sh

# Run the install-build-requirements script
RUN ./install-build-requirements.sh

# Source .cubrid_env.sh in .bashrc
RUN echo 'source $HOME/.cubrid_env.sh' >> .bashrc

# Set the entrypoint to bash
CMD ["/bin/bash"]
```

도커 이미지를 빌드하고 컨테이너를 실행합니다.

```bash
docker rm mycentos7 # optional
docker build -t mycentos7-image . && docker run -it --name mycentos7 mycentos7-image
```

---

### CUBRID 빌드하기

도커 컨테이너에 접속한 후, CUBRID 소스 레포지토리를 다운로드하고 다음 명령어를 실행합니다.

```bash
mkdir projects
cd projects
git clone https://github.com/cubrid/cubrid.git
cd cubrid
./build.sh -p $HOME/CUBRID -m debug -t 64 -g ninja 
```

이 명령어로 빌드에 성공할 수 있습니다.

첫 빌드 이후에는 동일한 명령어에 `build` 인자를 추가하면 더 빨리 빌드할 수 있습니다. 예를 들어,

```bash
./build.sh -p $HOME/CUBRID -m debug -t 64 -g ninja build
```

이와 같이 재빌드할 수 있습니다.
가끔 오류가 발생하거나 변경사항이 반영되지 않을 수 있으므로, 새로 빌드할 때마다 산출물인 `$HOME/CUBRID`를 삭제하는 것이 좋습니다. 예를 들어,

```bash
rm -rf $HOME/CUBRID && ./build.sh -p $HOME/CUBRID -m debug -t 64 -g ninja build
```

위와 같이 할 수 있습니다.

참고: 빌드에 오류가 자주 발생한다면

```sh
source scl_source enable devtoolset-8
```

이 명령어가 잘 실행되었는지, 매번 터미널을 열 때마다 실행되도록 `.cubrid_env.sh` 파일에 설정되었는지 확인해보시기 바랍니다.

---

### csql 실행하기

빌드가 완료된 후, 터미널에서 `csql` 명령어를 실행해봅니다.

```sh
csql
```

다음과 같은 메시지가 출력되면 `csql`이 정상적으로 실행되는 것입니다.

```
A database-name is missing.
interactive SQL utility, version 11.4
usage: csql [OPTION] database-name[@host]

valid options:
  -S, --SA-mode                standalone mode execution
  -C, --CS-mode                client-server mode execution
  -u, --user=ARG               alternate user name
  -p, --password=ARG           password string, give "" for none
  -e, --error-continue         don't exit on statement error
  -i, --input-file=ARG         input-file-name
...
```

만약 실행되지 않는다면 환경 변수를 올바르게 설정했는지 확인해보세요. 예를 들어,

```sh
export PATH="$CUBRID/bin:$PATH"
```

위와 같이 `PATH` 변수에 `$CUBRID/bin`을 추가했는지 확인합니다. 실행에 문제가 있다면 다음 환경 변수가 올바르게 설정되었는지 확인합니다.

```
LD_LIBRARY_PATH
JAVA_HOME
CUBRID
CUBRID_DATABASES
```

다음 명령어를 사용하여 standalone 모드로 데이터베이스에 접근할 수 있습니다.

```sh
csql -u dba demodb -S
```

이 시점에서는 아래와 같은 에러가 발생하는 것이 정상입니다.

```
ERROR: Database "demodb" is unknown, or the file "databases.txt" cannot be accessed.
```

---

### demodb 만들기

`$HOME/CUBRID`를 새로 만들 때마다 `demodb`를 생성해줘야 합니다. 위 에러가 발생한 이유는 아직 `demodb` 를 생성하지 않았기 때문입니다. 큐브리드는 개발자들을 위해 테스트용으로 간단한 `demodb`를 만드는 유틸리티를 지원합니다.

```sh
cd $CUBRID_DATABASES
mkdir demodb
cd demodb
../../demo/make_cubrid_demo.sh
```

위 명령어로 간단하게 `demodb`를 생성할 수 있습니다. `demo/make_cubrid_demo.sh`의 내용은 학습 목적으로 확인해보는 것이 좋습니다.

```sh
# make_cubrid_demo.sh

cubrid createdb --db-volume-size=100M --log-volume-size=100M demodb en_US.utf8  > /dev/null 2>&1
cubrid loaddb -u dba -s $CUBRID/demo/demodb_schema -d $CUBRID/demo/demodb_objects demodb > /dev/null 2>&1
```

각 명령어에 대한 자세한 내용은 CUBRID 매뉴얼을 참고하시기 바랍니다.

`make_cubrid_demo.sh`를 실행한 후 `demodb` 디렉토리에 다음과 같은 파일들이 생성되었다면 성공입니다.

```sh
ls
```

```
demodb  demodb_keys  demodb_lgar_t  demodb_lgat  demodb_lginf  demodb_loaddb.log  demodb_vinf  lob
```

이제 다시 `csql` 명령어를 사용하여 데이터베이스에 접속할 수 있습니다.

```sh
csql -u dba demodb -S
```

접속 후 `show tables;`와 `select * from code;` 명령어를 실행해보세요.

```sh
csql> show tables;

=== <Result of SELECT Command in Line 1> ===

  Tables_in_demodb
======================
  'athlete'
  'code'
  'event'
  'game'
  'history'
  'nation'
  'olympic'
  'participant'
  'record'
  'stadium'

10 rows selected. (0.028097 sec) Committed. (0.000256 sec)
```

```sh
csql> select * from code;

=== <Result of SELECT Command in Line 1> ===

  s_name                f_name
============================================
  'X'                   'Mixed'
  'W'                   'Woman'
  'M'                   'Man'
  'B'                   'Bronze'
  'S'                   'Silver'
  'G'                   'Gold'

6 rows selected. (0.008472 sec) Committed. (0.000102 sec)
```

위와 같은 결과가 나오면 성공입니다.

이후로는 다음 명령어를 반복하면서 개발을 진행할 수 있습니다.

```sh
#...
# 소스코드 수정
#...
rm -rf $HOME/CUBRID && ./build.sh -p $HOME/CUBRID -m debug -t 64 -g ninja build
cd $CUBRID_DATABASES
mkdir demodb
cd demodb
../../demo/make_cubrid_demo.sh
csql -u dba demodb -S
# 동작 확인
# 위 내용 반복 (소스 코드 수정 -> 재빌드 -> 디비 생성 -> csql 실행...)
```

도움이 되었기를 바랍니다.

다음에는 소스코드 수정 시 gdb와 VSCode를 CUBRID에 연결하는 방법에 대해 다루겠습니다.

읽어주셔서 감사합니다.
