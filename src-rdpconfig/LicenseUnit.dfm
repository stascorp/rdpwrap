object LicenseForm: TLicenseForm
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'License Agreement'
  ClientHeight = 344
  ClientWidth = 386
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object mText: TMemo
    Left = 8
    Top = 8
    Width = 370
    Height = 297
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object bAccept: TButton
    Left = 115
    Top = 311
    Width = 75
    Height = 25
    Caption = '&Accept'
    ModalResult = 1
    TabOrder = 1
  end
  object bDecline: TButton
    Left = 196
    Top = 311
    Width = 75
    Height = 25
    Caption = '&Decline'
    ModalResult = 2
    TabOrder = 2
  end
end
