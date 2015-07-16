object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RDP Wrapper Configuration'
  ClientHeight = 352
  ClientWidth = 351
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
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lRDPPort: TLabel
    Left = 225
    Top = 103
    Width = 47
    Height = 13
    Caption = 'RDP Port:'
  end
  object bOK: TButton
    Left = 10
    Top = 319
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    OnClick = bOKClick
  end
  object bCancel: TButton
    Left = 91
    Top = 319
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = bCancelClick
  end
  object bApply: TButton
    Left = 172
    Top = 319
    Width = 75
    Height = 25
    Caption = 'Apply'
    Enabled = False
    TabOrder = 2
    OnClick = bApplyClick
  end
  object cbSingleSessionPerUser: TCheckBox
    Left = 8
    Top = 112
    Width = 130
    Height = 17
    Caption = 'Single Session Per User'
    TabOrder = 3
    OnClick = cbAllowTSConnectionsClick
  end
  object rgNLA: TRadioGroup
    Left = 8
    Top = 132
    Width = 335
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
    Top = 89
    Width = 174
    Height = 17
    Caption = 'Enable Remote Desktop Protocol'
    TabOrder = 5
    OnClick = cbAllowTSConnectionsClick
  end
  object rgShadow: TRadioGroup
    Left = 8
    Top = 208
    Width = 335
    Height = 105
    Caption = 'Session Shadowing Mode'
    Items.Strings = (
      'Disable Shadowing'
      'Full access with user'#39's permission'
      'Full access without permission'
      'View only with user'#39's permission'
      'View only without permission')
    TabOrder = 6
    OnClick = cbAllowTSConnectionsClick
  end
  object seRDPPort: TSpinEdit
    Left = 278
    Top = 100
    Width = 62
    Height = 22
    MaxValue = 65535
    MinValue = 0
    TabOrder = 7
    Value = 0
    OnChange = seRDPPortChange
  end
  object bLicense: TButton
    Left = 253
    Top = 319
    Width = 87
    Height = 25
    Caption = 'View license...'
    TabOrder = 8
    OnClick = bLicenseClick
  end
  object gbDiag: TGroupBox
    Left = 8
    Top = 6
    Width = 335
    Height = 77
    Caption = 'Diagnostics'
    TabOrder = 9
    object lListener: TLabel
      Left = 11
      Top = 55
      Width = 70
      Height = 13
      Caption = 'Listener state:'
    end
    object lService: TLabel
      Left = 11
      Top = 36
      Width = 67
      Height = 13
      Caption = 'Service state:'
    end
    object lsListener: TLabel
      Left = 91
      Top = 55
      Width = 44
      Height = 13
      Caption = 'Unknown'
    end
    object lsService: TLabel
      Left = 91
      Top = 36
      Width = 44
      Height = 13
      Caption = 'Unknown'
    end
    object lsTSVer: TLabel
      Left = 206
      Top = 36
      Width = 44
      Height = 13
      Caption = 'Unknown'
    end
    object lsWrapper: TLabel
      Left = 91
      Top = 17
      Width = 44
      Height = 13
      Caption = 'Unknown'
    end
    object lsWrapVer: TLabel
      Left = 206
      Top = 17
      Width = 44
      Height = 13
      Caption = 'Unknown'
    end
    object lTSVer: TLabel
      Left = 182
      Top = 36
      Width = 20
      Height = 13
      Caption = 'ver.'
    end
    object lWrapper: TLabel
      Left = 11
      Top = 17
      Width = 74
      Height = 13
      Caption = 'Wrapper state:'
    end
    object lWrapVer: TLabel
      Left = 182
      Top = 17
      Width = 20
      Height = 13
      Caption = 'ver.'
    end
    object lsSuppVer: TLabel
      Left = 182
      Top = 55
      Width = 70
      Height = 13
      Caption = '[support level]'
    end
  end
  object Timer: TTimer
    Interval = 250
    OnTimer = TimerTimer
    Left = 280
    Top = 19
  end
end
