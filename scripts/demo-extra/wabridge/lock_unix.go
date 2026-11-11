//go:build !windows

package main

import (
	"os"
	"syscall"
	"time"
)

// Un solo puente por sesión: dos conexiones con la misma cuenta se echan una a otra.
// El candado es del sistema: se suelta solo si el proceso muere.
func lockSession(path string) (bool, func()) {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return false, func() {}
	}
	if syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB) != nil {
		f.Close()
		return false, func() {}
	}
	return true, func() { f.Close() }
}

// Si la app muere sin cerrar la entrada (o alguien la tiene abierta), el puente pasa a ser
// hijo de launchd: entonces también termina.
func watchParent(stop func()) {
	parent := os.Getppid()
	go func() {
		for range time.Tick(2 * time.Second) {
			if os.Getppid() != parent {
				stop()
				return
			}
		}
	}()
}
