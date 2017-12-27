object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RDP Wrapper Configuration'
  ClientHeight = 314
  ClientWidth = 404
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
  object bOK: TButton
    Left = 40
    Top = 281
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 4
    OnClick = bOKClick
  end
  object bCancel: TButton
    Left = 121
    Top = 281
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
    OnClick = bCancelClick
  end
  object bApply: TButton
    Left = 202
    Top = 281
    Width = 75
    Height = 25
    Caption = 'Apply'
    Enabled = False
    TabOrder = 6
    OnClick = bApplyClick
  end
  object rgNLA: TRadioGroup
    Left = 202
    Top = 89
    Width = 194
    Height = 73
    Caption = 'Authentication Mode'
    Items.Strings = (
      'GUI Authentication Only'
      'Default RDP Authentication'
      'Network Level Authentication')
    TabOrder = 2
    OnClick = cbAllowTSConnectionsClick
  end
  object rgShadow: TRadioGroup
    Left = 202
    Top = 168
    Width = 194
    Height = 105
    Caption = 'Session Shadowing Mode'
    Items.Strings = (
      'Disable Shadowing'
      'Full access with user'#39's permission'
      'Full access without permission'
      'View only with user'#39's permission'
      'View only without permission')
    TabOrder = 3
    OnClick = cbAllowTSConnectionsClick
  end
  object bLicense: TButton
    Left = 283
    Top = 281
    Width = 87
    Height = 25
    Caption = 'View license...'
    TabOrder = 7
    OnClick = bLicenseClick
  end
  object gbDiag: TGroupBox
    Left = 8
    Top = 6
    Width = 388
    Height = 77
    Caption = 'Diagnostics'
    TabOrder = 0
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
      Left = 226
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
      Left = 226
      Top = 17
      Width = 44
      Height = 13
      Caption = 'Unknown'
    end
    object lTSVer: TLabel
      Left = 202
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
      Left = 202
      Top = 17
      Width = 20
      Height = 13
      Caption = 'ver.'
    end
    object lsSuppVer: TLabel
      Left = 202
      Top = 55
      Width = 70
      Height = 13
      Caption = '[support level]'
    end
  end
  object gbGeneral: TGroupBox
    Left = 8
    Top = 89
    Width = 188
    Height = 184
    Caption = 'General Settings'
    TabOrder = 1
    object lRDPPort: TLabel
      Left = 8
      Top = 44
      Width = 47
      Height = 13
      Caption = 'RDP port:'
    end
    object cbAllowTSConnections: TCheckBox
      Left = 8
      Top = 18
      Width = 132
      Height = 17
      Caption = 'Enable Remote Desktop'
      TabOrder = 0
      OnClick = cbAllowTSConnectionsClick
    end
    object cbSingleSessionPerUser: TCheckBox
      Left = 8
      Top = 69
      Width = 129
      Height = 17
      Caption = 'Single session per user'
      TabOrder = 2
      OnClick = cbAllowTSConnectionsClick
    end
    object cbHideUsers: TCheckBox
      Left = 8
      Top = 92
      Width = 149
      Height = 17
      Caption = 'Hide users on logon screen'
      TabOrder = 3
      OnClick = cbAllowTSConnectionsClick
    end
    object seRDPPort: TSpinEdit
      Left = 61
      Top = 41
      Width = 62
      Height = 22
      MaxValue = 65535
      MinValue = 0
      TabOrder = 1
      Value = 0
      OnChange = seRDPPortChange
    end
    object cbCustomPrg: TCheckBox
      Left = 8
      Top = 115
      Width = 169
      Height = 17
      Caption = 'Allow to start custom programs'
      TabOrder = 4
      OnClick = cbAllowTSConnectionsClick
    end
  end
  object Timer: TTimer
    Interval = 250
    OnTimer = TimerTimer
    Left = 352
    Top = 27
  end
end
