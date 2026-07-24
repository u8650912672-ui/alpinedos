.intel_syntax noprefix
.global _start
.equ SYS_write,   1
.equ SYS_open,    2
.equ SYS_close,   3
.equ SYS_execve,  59
.equ SYS_exit,    60
.equ SYS_mount,   165
.equ SYS_reboot,  169
.equ SYS_prctl,   157
.equ O_WRONLY,    1
.equ MS_NOSUID,   2
.equ MS_NODEV,    4
.equ MS_NOEXEC,   8
.equ PR_SET_NO_NEW_PRIVS, 38
.equ RB_AUTOBOOT, 0x1234567
.section .rodata
proc_src:    .asciz "proc"
proc_tgt:    .asciz "/proc"
proc_type:   .asciz "proc"
proc_opts:   .asciz "hidepid=2"
sys_src:     .asciz "sysfs"
sys_tgt:     .asciz "/sys"
sys_type:    .asciz "sysfs"
dev_src:     .asciz "devtmpfs"
dev_tgt:     .asciz "/dev"
dev_type:    .asciz "devtmpfs"
pts_src:     .asciz "devpts"
pts_tgt:     .asciz "/dev/pts"
pts_type:    .asciz "devpts"
pts_opts:    .asciz "gid=5,mode=620"
run_src:     .asciz "tmpfs"
run_tgt:     .asciz "/run"
run_type:    .asciz "tmpfs"
shm_tgt:     .asciz "/dev/shm"
tmp_tgt:     .asciz "/tmp"
sh_path:     .asciz "/bin/sh"
path_env:    .asciz "PATH=/bin:/sbin:/usr/bin:/usr/sbin"
sys_kptr:       .asciz "/proc/sys/kernel/kptr_restrict"
sys_dmesg:      .asciz "/proc/sys/kernel/dmesg_restrict"
sys_kexec:      .asciz "/proc/sys/kernel/kexec_load_disabled"
sys_suid_dump:  .asciz "/proc/sys/fs/suid_dumpable"
val_0:    .asciz "0"
val_1:    .asciz "1"
val_2:    .asciz "2"
.section .data
.align 8
argv: .quad sh_path, 0
envp: .quad path_env, 0
.section .text
/* try mount — continues on failiure */
.macro try_mount src, tgt, type, flags, data
    mov rax, SYS_mount
    lea rdi, [rip + \src]
    lea rsi, [rip + \tgt]
    lea rdx, [rip + \type]
    mov r10, \flags
    .ifnb \data
        lea r8, [rip + \data]
    .else
        xor r8, r8
    .endif
    syscall
.endm
/* try sysctl — continues on failiure */
.macro sysctl path, val
    lea rdi, [rip + \path]
    mov rsi, O_WRONLY
    xor rdx, rdx
    mov rax, SYS_open
    syscall
    test rax, rax
    js 1f
    mov r15, rax
    mov rdi, r15
    lea rsi, [rip + \val]
    mov rdx, 1
    mov rax, SYS_write
    syscall
    mov rdi, r15
    mov rax, SYS_close
    syscall
1:
.endm
_start:
    /* mounts  */
    try_mount proc_src, proc_tgt, proc_type, 14, proc_opts
    try_mount sys_src,  sys_tgt,  sys_type,  14
    try_mount dev_src,  dev_tgt,  dev_type,  10
    try_mount pts_src,  pts_tgt,  pts_type,  10, pts_opts
    try_mount run_src,  run_tgt,  run_type,  14
    try_mount run_src,  shm_tgt,  run_type,  14
    try_mount run_src,  tmp_tgt,  run_type,  14
    /* kernel hardening — ueses teh working ones hopefully */
    sysctl sys_kptr,      val_2
    sysctl sys_dmesg,     val_1
    sysctl sys_kexec,     val_1
    sysctl sys_suid_dump, val_0
    /* no_new_privs  */
    mov rax, SYS_prctl
    mov rdi, PR_SET_NO_NEW_PRIVS
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    /* exec shell simplified and works :3? */
    mov rax, SYS_execve
    lea rdi, [rip + sh_path]
    lea rsi, [rip + argv]
    lea rdx, [rip + envp]
    syscall
    mov rax, SYS_reboot
    mov rdi, 0xfee1dead
    mov rsi, 0x4321fedc
    mov rdx, RB_AUTOBOOT
    syscall
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
