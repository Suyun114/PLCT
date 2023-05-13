source "$OET_PATH/libs/locallibs/common_lib.sh"

function config_params() {
    LOG_INFO "Start to config params of the case."

    # 创建一个用于测试的 C 源代码。
    LOG_INFO "Create a C source file for testing."
    cat > main.c << EOF
#include <stdio.h>
#include <assert.h>
#include <limits.h>

int main(void) {
    printf("Hello, world!\n");
    asm("");                   // 测试 -fno-asm 参数。

    int a = 1, b;              // 测试 -Wall 参数。
    assert(a < 2u);            // 测试 -Wextra 参数。

#ifdef MACRO                   // 测试 -D 参数。
    printf("MACRO is defined.");
#endif

    return 0;
}
EOF

    # 为了方便匹配输出日志，将语言设置为 en_US.UTF-8。
    LOG_INFO "Set the locale to en_US.UTF-8."
    prev_lang=$LANG
    LANG=en_US.UTF-8

    LOG_INFO "End to config params of the case."
}

function pre_test(){
    LOG_INFO "Start to prepare the test environment."

    # 安装待测试的 gcc 包。
    LOG_INFO "Install the pkg to be tested."
    DNF_INSTALL "gcc"

    LOG_INFO "End to prepare the test environment."
}

function run_test() {
    gcc main.c                       # 测试能否正常编译。
    test -f a.out                    # 若编译出的可执行文件 a.out 存在即表明正常编译。
    CHECK_RESULT $? 0 0 "Cannot compile the source file."

    gcc --version | grep 'gcc (GCC)' # 测试版本信息能否正常显示。
                                     # 若版本信息包含 gcc (GCC) 即表明版本信息正常显示。
    CHECK_RESULT $? 0 0 "The argument --version cannot work."

    gcc main.c -o Main               # 测试能否正常通过 -o 参数指定可执行文件名。
    test -f Main                     # 若 -o 指定的可执行文件名存在即为正常。
    CHECK_RESULT $? 0 0 "The argument -o cannot work."

    gcc main.c -S                    # 测试 -S 参数能否正常对源代码进行汇编。
    test -f main.s                   # 若汇编出的 .s 文件存在即正常。
    CHECK_RESULT $? 0 0 "The argument -S cannot work."

    rm a.out
    gcc main.s                       # 测试产生的汇编代码是否正常。
    test -f a.out                    # 若汇编代码能被正常编译即为正常。
    CHECK_RESULT $? 0 0 "The output of the argument -S is abnormal."

    rm a.out
    gcc main.c -fno-asm              # 测试 -fno-asm 参数能否正常禁用内联汇编。
                                     # 需要注意的是，禁用内联汇编后，代码无法被正常编译，所以返回值为 1 才是正常的。
    CHECK_RESULT $? 0 1 "The argument -fno-asm cannot work."

    rm a.out
    gcc main.c -E > main.i           # 测试 -E 参数能否正常对源代码进行预处理。
    grep '# 1 "main.c"' main.i       # 若预处理后的代码包含预处理语句，则正常。
    CHECK_RESULT $? 0 0 "The argument -E cannot work."

    gcc main.i                       # 测试预处理后的代码是否正常。
    test -f a.out                    # 若预处理后的代码可以被正常编译，则正常。
    CHECK_RESULT $? 0 0 "The output of the argument -E is abnormal."

    # 测试 -Wall 参数是否正常。
    # 若能对未使用的变量 b 进行警告，则正常。
    gcc main.c -Wall 2>&1 | grep 'warning: unused variable ‘b’'
    CHECK_RESULT $? 0 0 "The argument -Wall cannot work."

    # 测试 -Wextra 参数是否正常。
    # 若能对将有符号数和无符号数进行比较的行为进行警告，则正常。
    gcc main.c -Wextra 2>&1 | grep 'warning: comparison of integer expressions of different signedness: ‘int’ and ‘unsigned int’'
    CHECK_RESULT $? 0 0 "The argument -Wextra cannot work."

    # 测试能否通过 -Werror 参数将所有的警告认定为错误。
    gcc main.c -Werror 2>&1 | grep 'all warnings being treated as errors'
    CHECK_RESULT $? 0 0 "The argument -Werror cannot work."

    # 测试能否使用 -D 参数定义宏。
    rm a.out
    gcc main.c -DMACRO && ./a.out | grep 'MACRO is defined.'
    CHECK_RESULT $? 0 0 "The argument -D cannot work."

    # 测试能否使用 -g 参数为代码添加调试信息。
    rm a.out
    gcc main.c -g
    strings a.out | grep '.debug'
    CHECK_RESULT $? 0 0 "The argument -g cannot work."
}

function post_test() {
    LOG_INFO "Start to restore the test environment."

    # 移除测试的 gcc 软件包。
    LOG_INFO "Remove the tested pkg."
    DNF_REMOVE
    
    # 恢复原来的系统语言。
    LOG_INFO "Recover the previous locale."
    LANG=$prev_lang

    # 删除测试创建的源代码、可执行文件的临时文件。
    LOG_INFO "Remove the temporary files during the test."
    rm -rf main* Main a.out

    LOG_INFO "End to restore the test environment."
}

main $@
