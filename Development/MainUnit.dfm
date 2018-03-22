object MainForm: TMainForm
  Left = 114
  Top = 134
  Width = 696
  Height = 480
  Caption = 'MainForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 12
    Top = 12
    Width = 92
    Height = 13
    Caption = 'Loaded in DataSet:'
  end
  object GroupBox1: TGroupBox
    Left = 12
    Top = 40
    Width = 665
    Height = 137
    Caption = 'Design'
    TabOrder = 0
    object ShowDesigner: TButton
      Left = 16
      Top = 24
      Width = 173
      Height = 41
      Caption = 'ShowDesigner'
      TabOrder = 0
      OnClick = ShowDesignerClick
    end
  end
  object edLoadedInDS: TEdit
    Left = 108
    Top = 8
    Width = 569
    Height = 21
    ReadOnly = True
    TabOrder = 1
  end
  object ReportDesigner: TfrxDesigner
    DefaultScriptLanguage = 'PascalScript'
    DefaultFont.Charset = DEFAULT_CHARSET
    DefaultFont.Color = clWindowText
    DefaultFont.Height = -13
    DefaultFont.Name = 'Arial'
    DefaultFont.Style = []
    DefaultLeftMargin = 10
    DefaultRightMargin = 10
    DefaultTopMargin = 10
    DefaultBottomMargin = 10
    DefaultPaperSize = 9
    DefaultOrientation = poPortrait
    Restrictions = []
    RTLLanguage = False
    Left = 236
    Top = 44
  end
  object DSLoadedPDF: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 400
    Top = 84
    object DSLoadedPDFLOADED_DATA: TBlobField
      FieldName = 'LOADED_DATA'
    end
  end
  object frxDBLoadedPDF: TfrxDBDataset
    UserName = 'frxDBLoadedPDF'
    CloseDataSource = False
    DataSet = DSLoadedPDF
    Left = 400
    Top = 112
  end
end
