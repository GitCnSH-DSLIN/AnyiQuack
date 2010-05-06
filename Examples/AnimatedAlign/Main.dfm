object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Animated Align with TAQ (AccessQuery)'
  ClientHeight = 337
  ClientWidth = 635
  Color = clAppWorkSpace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnResize = FormResize
  DesignSize = (
    635
    337)
  PixelsPerInch = 96
  TextHeight = 13
  object Label3: TLabel
    Left = 324
    Top = 268
    Width = 311
    Height = 33
    Anchors = [akRight, akBottom]
    AutoSize = False
    Caption = 
      'Add a couple of panels and play with the size of form or panels.' +
      ' Also try the different handling for disturbed animations.'
    Color = clInfoBk
    ParentColor = False
    Transparent = True
    WordWrap = True
  end
  object TopPanel: TPanel
    Left = 0
    Top = 0
    Width = 635
    Height = 44
    Align = alTop
    BevelEdges = [beBottom]
    BevelKind = bkSoft
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object Label1: TLabel
      Left = 164
      Top = 1
      Width = 101
      Height = 13
      Caption = 'Disturbed Animations'
    end
    object Label2: TLabel
      Left = 8
      Top = 1
      Width = 47
      Height = 13
      Caption = 'Panel size'
    end
    object Label5: TLabel
      Left = 324
      Top = 1
      Width = 125
      Height = 13
      Caption = 'Animation duration (msec)'
    end
    object DisturbedComboBox: TComboBox
      Left = 164
      Top = 17
      Width = 145
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 0
      Text = 'Cancel'
      Items.Strings = (
        'Cancel'
        'Finish')
    end
    object PanelSizeTrackBar: TTrackBar
      Left = 0
      Top = 17
      Width = 150
      Height = 21
      Max = 200
      Min = 20
      Frequency = 20
      Position = 100
      PositionToolTip = ptBottom
      TabOrder = 1
      OnChange = PanelSizeTrackBarChange
    end
    object AnimationDurationTrackBar: TTrackBar
      Left = 318
      Top = 17
      Width = 150
      Height = 21
      Max = 1500
      Min = 100
      Position = 500
      PositionToolTip = ptBottom
      TabOrder = 2
    end
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 304
    Width = 635
    Height = 33
    Align = alBottom
    BevelEdges = [beTop]
    BevelKind = bkSoft
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      635
      31)
    object Label4: TLabel
      Left = 3
      Top = 8
      Width = 158
      Height = 13
      Anchors = [akLeft, akBottom]
      Caption = 'Note: Flickering is a issue of VCL.'
      ExplicitTop = 320
    end
    object AddPanelButton: TButton
      Left = 552
      Top = 1
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Add Panel'
      TabOrder = 0
      OnClick = AddPanelButtonClick
    end
    object RemovePanelButton: TButton
      Left = 464
      Top = 1
      Width = 82
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Remove Panel'
      Enabled = False
      TabOrder = 1
      OnClick = RemovePanelButtonClick
    end
  end
end
