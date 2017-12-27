@echo off
"%ProgramFiles%\WiX Toolset v3.11\bin\candle" RDPWInst.wxs
"%ProgramFiles%\WiX Toolset v3.11\bin\light" RDPWInst.wixobj
