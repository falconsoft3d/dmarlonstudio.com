//go:build windows

package main

import "syscall"

// Un solo puente por sesión: el archivo abierto sin compartir (lo suelta Windows si el proceso muere).
func lockSession(path string) (bool, func()) {
	p, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return false, func() {}
	}
	h, err := syscall.CreateFile(p, syscall.GENERIC_READ|syscall.GENERIC_WRITE, 0, nil, syscall.OPEN_ALWAYS,
		syscall.FILE_ATTRIBUTE_NORMAL, 0)
	if err != nil {
		return false, func() {}
	}
	return true, func() { syscall.CloseHandle(h) }
}

// En Windows, al morir la app se cierra su lado de la tubería: basta con la entrada.
func watchParent(stop func()) {}
