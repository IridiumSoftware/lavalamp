# Makefile for lavalamp_se_signer (LL-043).
#
# Apple Secure Enclave is available only on Apple Silicon Macs
# (and Intel Macs with the T2 chip). The build is macOS-only.

SWIFTC ?= swiftc
SWIFTFLAGS ?= -O -framework Security -framework CoreFoundation

TARGET := lavalamp_se_signer
SOURCE := lavalamp_se_signer.swift

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(SWIFTC) $(SWIFTFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)
