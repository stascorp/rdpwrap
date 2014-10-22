object Frm: TFrm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Local RDP Checker'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object RDP: TMsRdpClient2
    Left = 0
    Top = 0
    Width = 640
    Height = 480
    TabOrder = 0
    OnDisconnected = RDPDisconnected
    ControlData = {0003000008000200000000000B0000000B000000}
  end
end
