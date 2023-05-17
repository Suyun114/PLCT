# 如何提交自动化测试结果

自动化测试使用 mugen 的 `qemu_test.py` 脚本进行。测试结束后，需要提交的文件有工作目录下的 `logs` 文件夹和 `logs_failed` 文件夹。

同时，还需要分析测试结果，整理出 `result.csv` 和 `failureCause.csv` 两个表格，分别为测试结果概述和未通过的测试套的失败原因。

对于较大型的测试，还需要提交 `README.md` 文件，范例可见 [Automated_Test/Mugen/README.md · yunxiang/openEuler RISC-V 23.03 测试](https://gitee.com/yunxiangluo/openeuler-riscv-2303-test/blob/master/Automated_Test/Mugen/README.md)。

---

在此次练习中，我使用了 mugen 仓库中的 `lists/list_minimal` 作为测试套列表文件。其中，有部分测试套不存在，还有 `systemd` 和 `lvm2` 测试套无法正常运行。排除之后，我运行的测试套列表参见 `logs` 文件夹。
