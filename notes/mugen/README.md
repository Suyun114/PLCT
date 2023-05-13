# mugen 学习笔记

mugen 是 openEuler 社区使用的测试框架。

在使用 mugen 进行测试的过程中，需要了解「测试套（testsuite）」和「测试用例（testcase）」的概念。一个测试套对应一个待测试的程序，可以包含多个测试用例。

## 使用 mugen 进行本地测试

使用 Git clone mugen 的 repo（这里使用 openEuler RISC-V SIG 维护的分支）：

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
    "path": "$OET_PATH/testcases/foo", // 测试用例的路径。
                                       // $OET_PATH 表示 mugen 的根目录。
    "cases": [
        {
            "name": "foo_01"           // 测试用例的名称。
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
# $1：测试点的返回结果。
# $2：预期结果。
# $3：对比模式。0：返回结果和预期结果相对；1：返回结果和预期结果不等。
# $4：发现问题，输出到日志。
# $5：退出模式。0：发现问题后，继续执行后续程序；1：发现问题后，中断并退出此代码块。
```

#### 安装与卸载软件包

```shell
DNF_INSTALL "vim bc"
DNF_REMOVE "jq"
```

## 附件

- `gcc.json`：对 GCC 进行测试的测试套，应当存放在 `suitecases` 目录下。

- `gcc_01.sh`：对 GCC 进行测试的测试用例，应当存放在 `testcases/gcc` 目录下。

## TODO

- `DNF_INSTALL` 和 `DNF_REMOVE` 的高级用法。

- 使用 Python 编写测试用例。

- 调用 QEMU 进行虚拟机测试的脚本 `qemu_test.py` 的使用。


