{
  Copyright 2014 Stas'M Corp.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit LicenseUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TLicenseForm = class(TForm)
    mText: TMemo;
    bAccept: TButton;
    bDecline: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LicenseForm: TLicenseForm;

implementation

{$R *.dfm}

end.
