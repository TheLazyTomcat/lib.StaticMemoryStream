{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  StaticMemoryStream

    Very simple class intended to provide a way of accessing general memory
    location using usual streams.
    Unlike TMemoryStream, this implementation will not realocate the memory
    (an exception is raised when attempted), so it is safe to use it on
    pointers from external sources (libraries, OS, ...).

  Version 1.0 (2017-08-01)

  Last change 2019-09-30

  ©2017-2019 František Milt

  Contacts:
    František Milt: frantisek.milt@gmail.com

  Support:
    If you find this code useful, please consider supporting its author(s) by
    making a small donation using the following link(s):

      https://www.paypal.me/FMilt

  Changelog:
    For detailed changelog and history please refer to this git repository:

      github.com/TheLazyTomcat/Lib.StaticMemoryStream

  Dependencies:
    AuxTypes - github.com/TheLazyTomcat/Lib.AuxTypes

===============================================================================}
unit StaticMemoryStream;

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

interface

uses
  SysUtils, Classes,
  AuxTypes;

type
  ESMSException = class(Exception);

  ESMSCannotWrite  = class(ESMSException);

  ESMSCannotChangeMemory = class(ESMSException);

{===============================================================================
--------------------------------------------------------------------------------
                              TStaticMemoryStream
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TStaticMemoryStream - declaration
===============================================================================}

type
  TStaticMemoryStream = class(TStream)
  private
    fMemory:    Pointer;
    fSize:      TMemSize;
    fPosition:  Int64;
  protected
    Function GetSize: Int64; override;
    procedure SetSize(const NewValue: Int64); override;
  public
    constructor Create(Memory: Pointer; Size: TMemSize); overload;
    Function Read(var Buffer; Count: LongInt): LongInt; override;
    Function Write(const Buffer; Count: LongInt): LongInt; override;
    Function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    property Memory: Pointer read fMemory;
    property Size: TMemSize read fSize;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                          TWritableStaticMemoryStream
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TWritableStaticMemoryStream - declaration
===============================================================================}

  TWritableStaticMemoryStream = class(TStaticMemoryStream)
  public
    Function Write(const Buffer; Count: LongInt): LongInt; override;
  end;

implementation

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                              TStaticMemoryStream
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TStaticMemoryStream - implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TStaticMemoryStream - protected methods
-------------------------------------------------------------------------------}

Function TStaticMemoryStream.GetSize: Int64;
begin
Result := Int64(fSize);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TStaticMemoryStream.SetSize(const NewValue: Int64);
begin
raise ESMSCannotChangeMemory.Create('TStaticMemoryStream.SetSize: Cannot change size of static memory.');
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{-------------------------------------------------------------------------------
    TStaticMemoryStream - public methods
-------------------------------------------------------------------------------}

constructor TStaticMemoryStream.Create(Memory: Pointer; Size: TMemSize);
begin
inherited Create;
fMemory := Memory;
fSize := Size;
fPosition := 0;
end;

//------------------------------------------------------------------------------

Function TStaticMemoryStream.Read(var Buffer; Count: LongInt): LongInt;
begin
If (Count > 0) and (fPosition >= 0) then
  begin
    Result := Int64(fSize) - fPosition;
    If Result > 0 then
      begin
        If Result > Count then
          Result := Count;
      {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
        Move(Pointer(PtrUInt(fMemory) + PtrUInt(fPosition))^,Buffer,Result);
        Inc(fPosition,Result);
      {$IFDEF FPCDWM}{$POP}{$ENDIF}
      end
    else Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
Function TStaticMemoryStream.Write(const Buffer; Count: LongInt): LongInt;
begin
{$IFDEF FPC}
Result := 0;
{$ENDIF}
raise ESMSCannotWrite.Create('TStaticMemoryStream.Write: Write operation not allowed on static memory.');
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TStaticMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
case Origin of
  soBeginning:  fPosition := Offset;
  soCurrent:    fPosition := fPosition + Offset;
  soEnd:        fPosition := Int64(fSize) + Offset;
end;
Result := fPosition;
end;


{===============================================================================
--------------------------------------------------------------------------------
                          TWritableStaticMemoryStream
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TWritableStaticMemoryStream - implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TWritableStaticMemoryStream - public methods
-------------------------------------------------------------------------------}

Function TWritableStaticMemoryStream.Write(const Buffer; Count: LongInt): LongInt;
begin
If (Count > 0) and (fPosition >= 0) then
  begin
    Result := Int64(fSize) - fPosition;
    If Result > 0 then
      begin
        If Result > Count then
          Result := Count;
      {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
        Move(Buffer,Pointer(PtrUInt(fMemory) + PtrUInt(fPosition))^,Result);
        Inc(fPosition,Result);
      {$IFDEF FPCDWM}{$POP}{$ENDIF}
      end
    else Result := 0;
  end
else Result := 0;
end;

end.
