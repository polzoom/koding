package main

import (
	"io/ioutil"
	"os"
	"syscall"
)

func main() {
	shift(os.Args[1])
}

func shift(path string) {
	info, err := os.Lstat(path)
	if err != nil {
		panic(err)
	}

	err = os.Lchown(path, int(info.Sys().(*syscall.Stat_t).Uid+1000000), int(info.Sys().(*syscall.Stat_t).Gid+1000000))
	if err != nil {
		panic(err)
	}

	if info.IsDir() {
		children, err := ioutil.ReadDir(path)
		if err != nil {
			panic(err)
		}
		for _, child := range children {
			shift(path + "/" + child.Name())
		}
	}
}
