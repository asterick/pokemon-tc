void _interrupt(2) IRQ_WatchDog(void) {
	// TODO
}

void _exit( int i )
{
    i;
    _int(0x48);
}
