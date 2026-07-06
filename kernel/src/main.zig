export fn KernelMain() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
