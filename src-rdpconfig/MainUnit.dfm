object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RDP Wrapper Configuration'
  ClientHeight = 245
  ClientWidth = 326
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lRDPPort: TLabel
    Left = 203
    Top = 33
    Width = 47
    Height = 13
    Caption = 'RDP Port:'
  end
  object bOK: TButton
    Left = 45
    Top = 212
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    OnClick = bOKClick
  end
  object bCancel: TButton
    Left = 126
    Top = 212
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = bCancelClick
  end
  object bApply: TButton
    Left = 207
    Top = 212
    Width = 75
    Height = 25
    Caption = 'Apply'
    Enabled = False
    TabOrder = 2
    OnClick = bApplyClick
  end
  object cbSingleSessionPerUser: TCheckBox
    Left = 8
    Top = 31
    Width = 130
    Height = 17
    Caption = 'Single Session Per User'
    TabOrder = 3
    OnClick = cbAllowTSConnectionsClick
  end
  object rgNLA: TRadioGroup
    Left = 8
    Top = 54
    Width = 310
    Height = 73
    Caption = 'Security Mode'
    Items.Strings = (
      'Disable Security (not recommended)'
      'Default Authentication (compatibility with older clients)'
      'Network Level Authentication (best)')
    TabOrder = 4
    OnClick = cbAllowTSConnectionsClick
  end
  object cbAllowTSConnections: TCheckBox
    Left = 8
    Top = 8
    Width = 174
    Height = 17
    Caption = 'Enable Remote Desktop Protocol'
    TabOrder = 5
    OnClick = cbAllowTSConnectionsClick
  end
  object rgShadow: TRadioGroup
    Left = 8
    Top = 133
    Width = 310
    Height = 73
    Caption = 'Session Shadowing Mode'
    Items.Strings = (
      'Disable Shadowing'
      'Shadowing will request user permission'
      'Shadowing sessions immediately')
    TabOrder = 6
    OnClick = cbAllowTSConnectionsClick
  end
  object seRDPPort: TSpinEdit
    Left = 256
    Top = 30
    Width = 62
    Height = 22
    MaxValue = 65535
    MinValue = 0
    TabOrder = 7
    Value = 0
    OnChange = seRDPPortChange
  end
  object bLicense: TButton
    Left = 224
    Top = 6
    Width = 94
    Height = 21
    Caption = 'View license...'
    TabOrder = 8
    OnClick = bLicenseClick
  end
end
