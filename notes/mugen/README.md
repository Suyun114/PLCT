# mugen 学习笔记

mugen 是 openEuler 社区使用的测试框架。

在使用 mugen 进行测试的过程中，需要了解「测试套（testsuite）」和「测试用例（testcase）」的概念。一个测试套对应一个待测试的程序，可以包含多个测试用例。

## 使用 mugen 进行本地测试

使用 Git 克隆 mugen 的 repo（这里使用 openEuler RISC-V SIG 维护的分支）：

```shell-session
# git clone https://gitee.com/src-oerv/mugen
```

通过 `dep_install.sh` 脚本安装依赖：

```shell-session
# bash dep_install.sh
```

用 `mugen.sh` 的 `-c` 参数配置测试机的信息：

```shell-session
# bash mugen.sh -c                       \
                --ip       127.0.0.1     \ # 测试机的 IP 地址
                --user     root          \ # 测试机的登录用户，默认为 root
                --password openEuler12#$ \ # 测试机的登录密码
                --port     12055         \ # 测试机的 SSH 端口，默认为 22
```

然后就可以开始测试了：

- `bash mugen.sh -a`：执行所有测试用例。

- `bash mugen.sh -f testsuite`：执行指定测试套。

- `bash mugen.sh -f testsuite -r testcase`：执行指定测试用例。

## 编写测试套

测试套保存在 `suite2cases` 文件夹下，使用 JSON 格式。

以下是一个测试套的范例：

```json
{
    "path": "$OET_PATH/testcases/foo", // 测试用例的路径
                                       // $OET_PATH 表示 mugen 的根目录。
    "cases": [
        {
            "name": "foo_01"           // 测试用例的名称
        },
        {
            "name": "foo_02"           // 可以添加多个测试用例。
        }
    ]
}
```

## 编写测试用例

测试用例一般保存在 `testcases` 文件夹下，不同的测试套对应的测试用例一般建立不同的文件夹来保存。同时，保存测试用例的文件夹要和测试套中的 `path` 的值一致。

### 使用 Shell

在测试用例的开头，要通过以下命令导入 mugen 库：

```shell
source ${OET_PATH}/libs/locallibs/common_lib.sh
```

然后，编写 `config_params`、`pre_test`、`run_test`、`post_test` 四个函数，分别处理：

- 测试前需要预加载的数据、参数配置

- 测试对象、测试需要的工具等测试准备

- 测试的具体内容的执行

- 测试后的收尾工作，如测试环境的恢复

最后，使用以下命令开始测试：

```shell
main "$@"
```

在编写测试用例的过程中，mugen 提供了一些常用的函数。

#### 输出日志

`LOG_INFO`、`LOG_WARN`、`LOG_DEBUG`、`LOG_ERROR` 分别在测试过程中往日志中输出信息、警告信息、调试信息和错误信息。

#### 检查结果

```shell
CHECK_RESULT $1 $2 $3 $4 $5
# $1：测试点的返回结果
# $2：预期结果
# $3：对比模式 0：返回结果和预期结果相等；1：返回结果和预期结果不等
# $4：发现问题，输出到日志
# $5：退出模式 0：发现问题后，继续执行后续程序；1：发现问题后，中断并退出此代码块
```

#### 安装与卸载软件包

```shell
DNF_INSTALL "vim bc"
DNF_REMOVE "jq"
```

## 调用 QEMU 进行虚拟机测试

mugen 提供了一个调用 QEMU 进行虚拟机测试的脚本 `qemu_test.py`。

### 准备虚拟机

从软件源下载待测试的系统的镜像（`.qcow2.zst` 文件，需要使用 `unzstd` 命令解压为 `.zst` 文件）、引导加载程序（`fw_payload_oe_uboot_*.bin`）和启动脚本（`start_vm.sh`），保存到同一个目录中。

用启动脚本启动虚拟机，使用 Git 克隆 mugen 的 repo 到虚拟机下的一个目录（如 `/root/mugen`），再使用 `dep_install.sh` 脚本安装依赖。如果有需要，可以根据具体情况对虚拟机进行一些修改，如 [openEuler RISC-V 23.03 自动化测试说明](https://github.com/brsf11/Tarsier-Internship/blob/main/Testing/0331-23.03testing/README.md) 中提到的情况。

将虚拟机准备完成后，使用 `poweroff` 命令关闭虚拟机，记下 `.qcow2` 镜像文件的名字。

### 准备物理机

在物理机（不一定要运行 openEuler）上使用 Git 克隆 mugen 的 repo。这里不需要使用 `dep_install.sh` 安装依赖。

`qemu_test.py` 依赖 `paramiko` 这个 Python 库，可以使用 pip 安装，也可以直接使用操作系统上的包管理器安装。如 Arch Linux 可以使用 pacman 安装 `python-paramiko` 包。

### 编写配置文件

`qemu_test.py` 脚本的配置文件使用 JSON 格式。以下是一份范例：

```json
{
    "workingDir":"../20230331",            // 工作目录，即虚拟机文件保存的目录
    "bios":"fw_payload_oe_uboot_2304.bin", // 引导加载程序的文件名
    "drive":"mugen_ready.qcow2",           // 准备好的虚拟机镜像的文件名
    "user":"root",                         // 虚拟机的用户名
    "password":"openEuler12#$",            // 虚拟机的密码
    "threads":4,                           // 测试线程数
    "cores":4,                             // 为虚拟机分配的核心数
    "memory":4,                            // 为虚拟机分配的内存容量，单位为 GB
    "mugenNative":1,                       // 是否使用虚拟机上的测试套
    "detailed":1,                          // 是否在屏幕上打印详细日志
    "addDisk":1,                           // 添加的磁盘数量
    "mugenDir":"/root/mugen",              // 在虚拟机中 mugen 所在的目录
    "listFile":"lists/list_test",          // 需要测试的测试套列表文件
    "generate":1                           // 是否将测试套保存到物理机上
}
```

### 进行测试

使用以下命令调用脚本，使用 `config.json` 作为配置文件进行测试：

```shell-session
$ python qemu_test.py -F config.json
```

在测试刚开始时，脚本会轮询判断虚拟机是否启动，可能会出现 SSH 连接相关的报错，这是正常的。

测试完成后，可以在工作目录下的以下文件夹找到与测试有关的信息：

- `suite2cases_out`：被测试的测试套。

- `exec_log`：测试套在运行时产生的日志。

- `logs`：测试用例在运行时产生的日志。

### Troubleshooting

在进行测试的过程中，如果在运行脚本较长时间之后，脚本没有输出测试日志和测试结果，而只是持续输出线程信息（如 `Thread 0 is alive`），这个时候可以尝试使用 SSH 连接到配置文件中配置的 SSH 端口（如上文中的 `12055`），若 SSH 无法正常连接，则说明脚本运行失败。

这个时候可以使用 <kbd>Ctrl</kbd>+<kbd>C</kbd> 关闭脚本，检查工作目录下的 `logs` 目录来判断有那些测试套已经测试完毕，再从列表文件中删除已经测试完毕的测试套，最后重新运行脚本开始测试。

## 附件

- `gcc.json`：对 GCC 进行测试的测试套，应当存放在 `suitecases` 目录下。

- `gcc_01.sh`：对 GCC 进行测试的测试用例，应当存放在 `testcases/gcc` 目录下。

## TODO

- `DNF_INSTALL` 和 `DNF_REMOVE` 的高级用法。

- 使用 Python 编写测试用例。
