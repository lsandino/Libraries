Attribute VB_Name = "Psychrometrics"
' This psychrometrics package is used to demonstrate psychrometric calculations.
' It contains functions to calculate dew point temperature, wet bulb temperature,
' relative humidity, humidity ratio, partial pressure of water vapor, moist air
' enthalpy, moist air volume, specific volume, and degree of saturation, given
' dry bulb temperature and another psychrometric variable. The code also includes
' functions for standard atmosphere calculation.
' The functions implement formulae found in the 2005 ASHRAE Handbook of Fundamentals.
' This version of the library works in SI units.
'
' This library was originally developed by Didier Thevenard, PhD, P.Eng., while 
' working of simulation software for solar energy systems and climatic data processing.
' It has since been moved to GitHub at https:'github.com/psychrometrics/libraries
' along with its documentation.
'
' Note from the author: I have made every effort to ensure that the code is adequate,
' however I make no representation with respect to its accuracy. Use at your
' own risk. Should you notice any error, or if you have suggestions on how to
' improve the code, please notify me through GitHub.
'
'-----------------------------------------------------------------------------
' History
' v. 1.1 - 13 Jan 2013
'    Changed 0.62198 to 0.621945 in GetVapPresFromHumRatio
'-----------------------------------------------------------------------------
'
' Legal notice
'
' This file is provided for free.  You can redistribute it and/or
' modify it under the terms of the GNU General Public
' License as published by the Free Software Foundation
' (version 3 or later).
'
' This source code is distributed in the hope that it will be useful
' but WITHOUT ANY WARRANTY; without even the implied
' warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
' PURPOSE. See the GNU General Public License for more
' details.
'
'  You should have received a copy of the GNU General Public License
'  along with this code.  If not, see <http:'www.gnu.org/licenses/>.
'

Option Explicit

Const RGAS = 8.314472        ' Universal gas constant in J/mol/K
Const MOLMASSAIR = 0.028966  ' mean molar mass of dry air in kg/mol
Const KILO = 1000            ' exact
Const ZEROC = 273.15         ' Zero ºC expressed in K
Const ERRVAL = -999999       ' Error value

' Conversions from Celsius to Kelvin
Function CTOK(ByVal T_C As Variant) As Variant
  CTOK = (T_C + ZEROC)
End Function

' Conversions from Celsius to Farenheit
Function CTOF(ByVal T_C As Variant) As Variant
  CTOF = 9 / 5 * T_C + 32   ' Exact
End Function

' Conversions from Farenheit to Celsius
Function FTOC(ByVal T_F As Variant) As Variant
  FTOC = 5 / 9 * (T_F - 32) ' Exact
End Function

' Error message output
Function MyMsgBox(ByVal ErrMsg As String)
  MsgBox (ErrMsg)
End Function

' Minimum function to return min of two numbers
Function Min(ByVal Num1 As Variant, ByVal Num2 As Variant) As Variant
  If (Num1 <= Num2) Then
    Min = Num1
  Else
    Min = Num2
  End If
End Function

'*****************************************************************************
' Conversions between dew point, wet bulb, and relative humidity
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''
' Wet-bulb temperature given dry-bulb temperature and dew-point temperature
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2009) ch. 1

Function GetTWetBulbFromTDewPoint(ByVal TDryBulb As Variant, ByVal TDewPoint As Variant, ByVal Pressure As Variant) As Variant
    ' GetTWetBulbFromTDewPoint:  (o) Wet bulb temperature [C]
    ' TDryBulb: (i) Dry bulb temperature [C]
    ' TDewPoint: (i) Dew point temperature [C]
    ' Pressure: (i) Atmospheric pressure [Pa]
    
  Dim HumRatio As Variant
  If TDewPoint <= TDryBulb Then
    HumRatio = GetHumRatioFromTDewPoint(TDewPoint, Pressure)
    If IsError(HumRatio) Then
      GetTWetBulbFromTDewPoint = CVErr(2042)
    Else
      GetTWetBulbFromTDewPoint = GetTWetBulbFromHumRatio(TDryBulb, HumRatio, Pressure)
    End If
  Else
    GetTWetBulbFromTDewPoint = CVErr(2042)
    MyMsgBox ("Dew point temperature is above dry bulb temperature")
  End If

End Function


'''''''''''''''''''''''''''''''''''''''
' Wet-bulb temperature given dry-bulb temperature and relative humidity
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2009) ch. 1

Function GetTWetBulbFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant, ByVal Pressure As Variant) As Variant
  ' GetTWetBulbFromRelHum: (o) Wet bulb temperature [C]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' RelHum: (i) Relative humidity [0-1]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  Dim HumRatio As Variant
  If IsError(RelHum) Then
    GetTWetBulbFromRelHum = CVErr(2042)
  Else
    If (RelHum > 0 And RelHum <= 1) Then
      HumRatio = GetHumRatioFromRelHum(TDryBulb, RelHum, Pressure)
      GetTWetBulbFromRelHum = GetTWetBulbFromHumRatio(TDryBulb, HumRatio, Pressure)
    Else
      GetTWetBulbFromRelHum = CVErr(2042)
      MyMsgBox ("Relative humidity is outside range [0,1]")
    End If
  End If

End Function


'''''''''''''''''''''''''''''''''''''''
' Relative Humidity given dry-bulb temperature and dew-point temperature
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2009) ch. 1
'
Function GetRelHumFromTDewPoint(ByVal TDryBulb As Variant, ByVal TDewPoint As Variant) As Variant
  ' GetRelHumFromTDewPoint: (o) Relative humidity [0-1]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' TDewPoint: (i) Dew point temperature [C]
  Dim VapPres As Variant
  Dim SatVapPres As Variant

  If TDewPoint <= TDryBulb Then
    VapPres = GetSatVapPres(TDewPoint)     ' Eqn. 36
    SatVapPres = GetSatVapPres(TDryBulb)
    GetRelHumFromTDewPoint = VapPres / SatVapPres             ' Eqn. 24
  Else
    GetRelHumFromTDewPoint = CVErr(2042)
    MyMsgBox ("Dew point temperature is above dry bulb temperature")
  End If
    
End Function


'''''''''''''''''''''''''''''''''''''''
' Relative Humidity given dry-bulb temperature and wet bulb temperature
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2005) ch. 1
'
Function GetRelHumFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetRelHumFromTWetBulb: (o) Relative humidity [0-1]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' TWetBulb: (i) Wet bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]

  Dim HumRatio As Variant
  If TWetBulb <= TDryBulb Then
    HumRatio = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)
    GetRelHumFromTWetBulb = GetRelHumFromHumRatio(TDryBulb, HumRatio, Pressure)
  Else
    GetRelHumFromTWetBulb = CVErr(2042)
    MyMsgBox ("Wet bulb temperature is above dry bulb temperature")
  End If

End Function


'''''''''''''''''''''''''''''''''''''''
' Dew Point Temperature given dry bulb temperature and relative humidity
' ASHRAE Fundamentals (2005) ch. 6 eqn 24
' ASHRAE Fundamentals (2009) ch. 1 eqn 24
'
Function GetTDewPointFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant) As Variant
  ' GetTDewPointFromRelHum: (o) Dew Point temperature [C]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' RelHum: (i) Relative humidity [0-1]
 
  Dim VapPres As Variant
 
  If RelHum > 0 And RelHum <= 1 Then
    VapPres = GetVapPresFromRelHum(TDryBulb, RelHum)
    GetTDewPointFromRelHum = GetTDewPointFromVapPres(TDryBulb, VapPres)
  Else
    GetTDewPointFromRelHum = CVErr(2042)
    MyMsgBox ("Relative humidity is outside 0%-100% range")
  End If
    
End Function


'''''''''''''''''''''''''''''''''''''''
' Dew Point Temperature given dry bulb temperature and wet bulb temperature
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2009) ch. 1
'
Function GetTDewPointFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetTDewPointFromTWetBulb: (o) Dew Point temperature [C]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' TWetBulb: (i) Wet bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]
  Dim HumRatio As Variant
  
  If TWetBulb <= TDryBulb Then
    HumRatio = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)
    GetTDewPointFromTWetBulb = GetTDewPointFromHumRatio(TDryBulb, HumRatio, Pressure)
  Else
    GetTDewPointFromTWetBulb = CVErr(2042)
    MyMsgBox ("Wet bulb temperature is above dry bulb temperature")
  End If
  
End Function



'*****************************************************************************
'  Conversions between dew point, or relative humidity and vapor pressure
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''/
' Partial pressure of water vapor as a function of relative humidity and
' temperature in C
' ASHRAE Fundamentals (2005) ch. 6, eqn. 24
' ASHRAE Fundamentals (2009) ch. 1, eqn. 24
'
Function GetVapPresFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant) As Variant
  ' GetVapPresFromRelHum: (o) Partial pressure of water vapor in moist air [Pa]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' RelHum: (i) Relative humidity [0-1]
  
  If RelHum > 0 And RelHum <= 1 Then
    GetVapPresFromRelHum = RelHum * GetSatVapPres(TDryBulb)
  Else
    GetVapPresFromRelHum = CVErr(2042)
    MyMsgBox ("Relative humidity is outside range [0,1]")
  End If

End Function


'''''''''''''''''''''''''''''''''''''''
' Relative Humidity given dry bulb temperature and vapor pressure
' ASHRAE Fundamentals (2005) ch. 6, eqn. 24
' ASHRAE Fundamentals (2009) ch. 1, eqn. 24
'
Function GetRelHumFromVapPres(ByVal TDryBulb As Variant, ByVal VapPres As Variant) As Variant
  ' GetRelHumFromVapPres: (o) Relative humidity [0-1]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' VapPres: (i) Partial pressure of water vapor in moist air [Pa]
  
  If IsError(VapPres) Then
    GetRelHumFromVapPres = CVErr(2042)
  Else
    If (VapPres >= 0) Then
      GetRelHumFromVapPres = VapPres / GetSatVapPres(TDryBulb)
    Else
      GetRelHumFromVapPres = CVErr(2042)
      MyMsgBox ("Partial pressure of water vapor in moist air is negative")
    End If
  End If
End Function


'''''''''''''''''''''''''''''''''''''''
' Dew point temperature given vapor pressure and dry bulb temperature
' ASHRAE Fundamentals (2005) ch. 6, eqn. 39 and 40
' ASHRAE Fundamentals (2009) ch. 1, eqn. 39 and 40
'
Function GetTDewPointFromVapPres(ByVal TDryBulb As Variant, ByVal VapPres As Variant) As Variant
  ' GetTDewPointFromVapPres: (o) Dew Point temperature [C]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' VapPres: (i) Partial pressure of water vapor in moist air [Pa]
  Dim alpha As Variant
  Dim TDewPoint As Variant
  Dim VP As Variant

  If IsError(VapPres) Then
    GetTDewPointFromVapPres = CVErr(2042)
  Else
    If (VapPres >= 0) Then
      VP = VapPres / 1000
      alpha = Log(VP)
      
      If (TDryBulb >= 0 And TDryBulb <= 93) Then    ' (39)
        TDewPoint = 6.54 + 14.526 * alpha + 0.7389 * alpha * alpha + 0.09486 * alpha ^ 3 + 0.4569 * VP ^ 0.1984
      ElseIf (TDryBulb < 0) Then ' (40)
        TDewPoint = 6.09 + 12.608 * alpha + 0.4959 * alpha * alpha
      Else
        TDewPoint = ERRVAL  ' Invalid value
        GetTDewPointFromVapPres = CVErr(2042)
        MyMsgBox ("Invalid temperature")
      End If
      GetTDewPointFromVapPres = Min(TDewPoint, TDryBulb)
    Else
      GetTDewPointFromVapPres = CVErr(2042)
      MyMsgBox ("Partial pressure of water vapor in moist air is negative")
    End If
  End If

  
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Vapor pressure given dew point temperature
' ASHRAE Fundamentals (2005) ch. 6 eqn. 38
' ASHRAE Fundamentals (2009) ch. 1 eqn. 38
'
Function GetVapPresFromTDewPoint(ByVal TDewPoint As Variant) As Variant
  ' GetVapPresFromTDewPoint: (o) Partial pressure of water vapor in moist air [Pa]
  ' TDewPoint: (i) Dew point temperature [C]
  GetVapPresFromTDewPoint = GetSatVapPres(TDewPoint)
End Function



'*****************************************************************************
'        Conversions from wet bulb temperature, dew point temperature,
'                or relative humidity to humidity ratio
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''
' Wet bulb temperature given humidity ratio
' ASHRAE Fundamentals (2005) ch. 6 eqn. 35
'
Function GetTWetBulbFromHumRatio(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetTWetBulbFromHumRatio: (o) Wet bulb temperature [C]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  ' Declarations
  Dim Wstar As Variant
  Dim TDewPoint As Variant, TWetBulb As Variant, TWetBulbSup As Variant, TWetBulbInf As Variant
  
  If IsError(HumRatio) Then
    GetTWetBulbFromHumRatio = CVErr(2042)
  Else
    If HumRatio > 0 Then
    
      TDewPoint = GetTDewPointFromHumRatio(TDryBulb, HumRatio, Pressure)
      
      ' Initial guesses
      TWetBulbSup = TDryBulb
      TWetBulbInf = TDewPoint
      TWetBulb = (TWetBulbInf + TWetBulbSup) / 2
      
      ' Bisection loop
      While (TWetBulbSup - TWetBulbInf > 0.001)
      
       ' Compute humidity ratio at temperature Tstar
       Wstar = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)
    
       ' Get new bounds
       If (Wstar > HumRatio) Then
        TWetBulbSup = TWetBulb
       Else
        TWetBulbInf = TWetBulb
       End If
    
       ' New guess of wet bulb temperature
       TWetBulb = (TWetBulbSup + TWetBulbInf) / 2
       
      Wend
    
      GetTWetBulbFromHumRatio = TWetBulb
    Else
      GetTWetBulbFromHumRatio = CVErr(2042)
      MyMsgBox ("Humidity ratio is negative")
    End If
  End If

End Function



'''''''''''''''''''''''''''''''''''''''
' Humidity ratio given wet bulb temperature and dry bulb temperature
' ASHRAE Fundamentals (2005) ch. 6 eqn. 35
' ASHRAE Fundamentals (2009) ch. 1 eqn. 35
'
Function GetHumRatioFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetHumRatioFromTWetBulb: (o) Humidity Ratio [kgH2O/kgAIR]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' TWetBulb: (i) Wet bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]

  Dim Wsstar As Variant

  If TWetBulb <= TDryBulb Then
    Wsstar = GetSatHumRatio(TWetBulb, Pressure)
    GetHumRatioFromTWetBulb = ((2501 - 2.326 * TWetBulb) * Wsstar - 1.006 * (TDryBulb - TWetBulb)) / (2501 + 1.86 * TDryBulb - 4.186 * TWetBulb)
  Else
    MyMsgBox ("Wet bulb temperature is above dry bulb temperature")
    GetHumRatioFromTWetBulb = CVErr(2042)
  End If
End Function


'''''''''''''''''''''''''''''''''''''''
' Humidity ratio given relative humidity
' ASHRAE Fundamentals (2005) ch. 6 eqn. 38
' ASHRAE Fundamentals (2009) ch. 1 eqn. 38
'
Function GetHumRatioFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant, ByVal Pressure As Variant) As Variant
  ' GetHumRatioFromRelHum: (o) Humidity Ratio [kgH2O/kgAIR]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' RelHum: (i) Relative humidity [0-1]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  Dim VapPres As Variant
  
  If IsError(RelHum) Then
    GetHumRatioFromRelHum = CVErr(2042)
  Else
    If RelHum > 0 And RelHum <= 1 Then
      VapPres = GetVapPresFromRelHum(TDryBulb, RelHum)
      GetHumRatioFromRelHum = GetHumRatioFromVapPres(VapPres, Pressure)
      If GetHumRatioFromRelHum < 0 Then
        GetHumRatioFromRelHum = CVErr(2042)
        MyMsgBox ("Humidity ratio is negative")
      End If
    Else
      GetHumRatioFromRelHum = CVErr(2042)
      MyMsgBox ("Relative humidity is outside range [0,1]")
    End If
  End If
  
End Function



'''''''''''''''''''''''''''''''''''''''
' Relative humidity given humidity ratio
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2005) ch. 1
'
Function GetRelHumFromHumRatio(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetRelHumFromHumRatio: (o) Relative humidity [0-1]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  Dim VapPres As Variant
    
  If IsError(HumRatio) Then
    GetRelHumFromHumRatio = CVErr(2042)
  Else
    If HumRatio > 0 Then
      VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
      GetRelHumFromHumRatio = GetRelHumFromVapPres(TDryBulb, VapPres)
    Else
      MyMsgBox ("Humidity ratio is negative")
      GetRelHumFromHumRatio = CVErr(2042)
    End If
  End If
End Function


'''''''''''''''''''''''''''''''''''''''
' Humidity ratio given dew point temperature and pressure.
' ASHRAE Fundamentals (2005) ch. 6 eqn. 22
' ASHRAE Fundamentals (2009) ch. 1 eqn. 22
'
Function GetHumRatioFromTDewPoint(ByVal TDewPoint As Variant, ByVal Pressure As Variant) As Variant
  ' GetHumRatioFromTDewPoint: (o) Humidity Ratio [kgH2O/kgAIR]
  ' TDewPoint: (i) Dew point temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  Dim VapPres As Variant
  VapPres = GetSatVapPres(TDewPoint)
  GetHumRatioFromTDewPoint = GetHumRatioFromVapPres(VapPres, Pressure)
  
  If GetHumRatioFromTDewPoint < 0 Then
    GetHumRatioFromTDewPoint = CVErr(2042)
    MyMsgBox ("Humidity ratio is negative")
  End If
  
End Function

'''''''''''''''''''''''''''''''''''''''
' Dew point temperature given dry bulb temperature, humidity ratio, and pressure
' ASHRAE Fundamentals (2005) ch. 6
' ASHRAE Fundamentals (2009) ch. 1
'
Function GetTDewPointFromHumRatio(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetTDewPointFromHumRatio: (o) Dew Point temperature [C]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  Dim VapPres As Variant
  
  If IsError(HumRatio) Then
    GetTDewPointFromHumRatio = CVErr(2042)
  Else
    If HumRatio > 0 Then
      VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
      GetTDewPointFromHumRatio = GetTDewPointFromVapPres(TDryBulb, VapPres)
    Else
      GetTDewPointFromHumRatio = CVErr(2042)
      MyMsgBox ("Humidity ratio is negative")
    End If
  End If
End Function


'*****************************************************************************
'       Conversions between humidity ratio and vapor pressure
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''/
' Humidity ratio given water vapor pressure and atmospheric pressure
' ASHRAE Fundamentals (2005) ch. 6 eqn. 22
' ASHRAE Fundamentals (2005) ch. 6 eqn. 22
'
Function GetHumRatioFromVapPres(ByVal VapPres As Variant, ByVal Pressure As Variant) As Variant
  ' GetHumRatioFromVapPres: (o) Humidity Ratio [kgH2O/kgAIR]
  ' VapPres: (i) Partial pressure of water vapor in moist air [Pa]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  If IsError(VapPres) Or VapPres < 0 Then
    GetHumRatioFromVapPres = CVErr(2042)
    MyMsgBox ("Partial pressure of water vapor in moist air is negative")
  Else
    GetHumRatioFromVapPres = 0.621945 * VapPres / (Pressure - VapPres)
  End If
  
End Function




'''''''''''''''''''''''''''''''''''''''
' Vapor pressure given humidity ratio and pressure
' ASHRAE Fundamentals (2005) ch. 6 eqn. 22
' ASHRAE Fundamentals (2009) ch. 1 eqn. 22
'
Function GetVapPresFromHumRatio(ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetVapPresFromHumRatio: (o) Partial pressure of water vapor in moist air [Pa]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
   Dim VapPres As Variant

  If IsError(HumRatio) Then
    GetVapPresFromHumRatio = CVErr(2042)
  Else
    If HumRatio > 0 Then
      VapPres = Pressure * HumRatio / (0.621945 + HumRatio)
      GetVapPresFromHumRatio = VapPres
    Else
      GetVapPresFromHumRatio = CVErr(2042)
      MyMsgBox ("Humidity ratio is negative")
    End If
  End If
  
End Function


'*****************************************************************************
'                             Dry Air Calculations
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''
' Dry air enthalpy given dry bulb temperature.
' ASHRAE Fundamentals (2005) ch. 6 eqn. 30
' ASHRAE Fundamentals (2009) ch. 1 eqn. 30
'
Function GetDryAirEnthalpy(ByVal TDryBulb As Variant) As Variant
  ' GetDryAirEnthalpy: (o) Dry air enthalpy [J/kg]
  ' TDryBulb: (i) Dry bulb temperature [C]
  
  GetDryAirEnthalpy = 1.006 * TDryBulb * KILO
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Dry air density given dry bulb temperature and pressure.
' ASHRAE Fundamentals (2005) ch. 6 eqn. 28
' ASHRAE Fundamentals (2009) ch. 1 eqn. 28
'
Function GetDryAirDensity(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetDryAirDensity: (o) Dry air density [kg/m3]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]
  GetDryAirDensity = Pressure * MOLMASSAIR / (RGAS * CTOK(TDryBulb))
End Function


'''''''''''''''''''''''''''''''''''''''
' Dry air volume given dry bulb temperature and pressure.
' ASHRAE Fundamentals (2005) ch. 6 eqn. 28
' ASHRAE Fundamentals (2009) ch. 1 eqn. 28
'
Function GetDryAirVolume(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetDryAirVolume: (o) Dry air volume [m3/kg]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  GetDryAirVolume = (RGAS * CTOK(TDryBulb)) / (Pressure * MOLMASSAIR)
End Function



'*****************************************************************************
'                       Saturated Air Calculations
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''
' Saturation vapor pressure as a function of temperature
' ASHRAE Fundamentals (2005) ch. 6 eqn. 5, 6
' ASHRAE Fundamentals (2009) ch. 1 eqn. 5, 6
'
Function GetSatVapPres(ByVal TDryBulb As Variant) As Variant
  ' GetSatVapPres: (o) Vapor Pressure of saturated air [Pa]
  ' TDryBulb: (i) Dry bulb temperature [C]
  
  Dim LnPws As Variant, T As Variant
  
  If IsError(TDryBulb) Then
    GetSatVapPres = CVErr(2042)
  Else
    If TDryBulb >= -100 And TDryBulb <= 200 Then
        T = CTOK(TDryBulb)
        
        If (TDryBulb >= -100 And TDryBulb <= 0) Then
          LnPws = (-5.6745359 * 10 ^ 3 / T + 6.3925247 - 9.677843 * 10 ^ -3 * T + 6.2215701 * 10 ^ -7 * T * T)
          LnPws = LnPws + 2.0747825 * 10 ^ -9 * T ^ 3 - 9.484024 * 10 ^ -13 * T ^ 4 + 4.1635019 * Log(T)
        ElseIf (TDryBulb > 0 And TDryBulb <= 200) Then
          LnPws = -5800.2206 / T + 1.3914993 - 0.048640239 * T + 0.000041764768 * T * T - 0.000000014452093 * T ^ 3 + 6.5459673 * Log(T)
        Else
          GetSatVapPres = CVErr(2042)             ' TDryBulb is out of range [-100, 200]
          MyMsgBox ("Dry bulb temperature is outside range [-100, 200]")
        End If
        GetSatVapPres = Exp(LnPws)
        
    Else
      GetSatVapPres = CVErr(2042)
      MyMsgBox ("Dry bulb temperature is outside range [-100, 200]")
    End If
  End If
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Humidity ratio of saturated air given dry bulb temperature and pressure.
' ASHRAE Fundamentals (2005) ch. 6 eqn. 23
' ASHRAE Fundamentals (2009) ch. 1 eqn. 23
'
Function GetSatHumRatio(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetSatHumRatio: (o) Humidity ratio of saturated air [kgH2O/kgAIR]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]
  Dim SatVaporPres As Variant
  
  SatVaporPres = GetSatVapPres(TDryBulb)
  
  If IsError(SatVaporPres) Then
    GetSatHumRatio = CVErr(2042)
  Else
    GetSatHumRatio = 0.621945 * SatVaporPres / (Pressure - SatVaporPres)
  End If
  
End Function

'''''''''''''''''''''''''''''''''''''''
' Saturated air enthalpy given dry bulb temperature and pressure
' ASHRAE Fundamentals (2005) ch. 6 eqn. 32
'
Function GetSatAirEnthalpy(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
  ' GetSatAirEnthalpy: (o) Saturated air enthalpy [J/kg]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  GetSatAirEnthalpy = GetMoistAirEnthalpy(TDryBulb, GetSatHumRatio(TDryBulb, Pressure))
  
End Function


'*****************************************************************************
'                       Moist Air Calculations
'*****************************************************************************


'''''''''''''''''''''''''''''''''''''''
' Vapor pressure deficit in Pa given humidity ratio, dry bulb temperature, and
' pressure.
' See Oke (1987) eqn. 2.13a
'
Function GetVPD(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetVPD: (o) Vapor pressure deficit [Pa]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  Dim RelHum As Variant

  If IsError(HumRatio) Then
    GetVPD = CVErr(2042)
  Else
    If HumRatio > 0 Then
      RelHum = GetRelHumFromHumRatio(TDryBulb, HumRatio, Pressure)
      GetVPD = GetSatVapPres(TDryBulb) * (1 - RelHum)
    Else
      GetVPD = CVErr(2042)
      MyMsgBox ("Humidity ratio is negative")
    End If
  End If
  
End Function


'''''''''''''''''''''''''''''''''''''''
' ASHRAE Fundamentals (2005) ch. 6 eqn. 12
'
Function GetDegreeOfSaturation(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetDegreeOfSaturation: (o) Degree of saturation []
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  If IsError(HumRatio) Then
    GetDegreeOfSaturation = CVErr(2042)
  ElseIf HumRatio > 0 Then
    GetDegreeOfSaturation = HumRatio / GetSatHumRatio(TDryBulb, Pressure)
  Else
    GetDegreeOfSaturation = CVErr(2042)
    MyMsgBox ("Humidity ratio is negative")
  End If
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Moist air enthalpy given dry bulb temperature and humidity ratio
' ASHRAE Fundamentals (2005) ch. 6 eqn. 32
' ASHRAE Fundamentals (2009) ch. 1 eqn. 32
'
Function GetMoistAirEnthalpy(ByVal TDryBulb As Variant, ByVal HumRatio As Variant) As Variant
  ' GetMoistAirEnthalpy: (o) Moist Air Enthalpy [J/kg]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  
  If IsError(HumRatio) Then
    GetMoistAirEnthalpy = CVErr(2042)
  ElseIf HumRatio > 0 Then
    GetMoistAirEnthalpy = (1.006 * TDryBulb + HumRatio * (2501 + 1.86 * TDryBulb)) * KILO
  Else
    GetMoistAirEnthalpy = CVErr(2042)
    MyMsgBox ("Humidity ratio is negative")
  End If
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Moist air volume given dry bulb temperature, humidity ratio, and pressure.
' ASHRAE Fundamentals (2005) ch. 6 eqn. 28
' ASHRAE Fundamentals (2009) ch. 1 eqn. 28
'
Function GetMoistAirVolume(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetMoistAirVolume: (o) Specific Volume [m3/kg]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  If IsError(HumRatio) Then
    GetMoistAirVolume = CVErr(2042)
  ElseIf HumRatio > 0 Then
    GetMoistAirVolume = 0.287042 * (CTOK(TDryBulb)) * (1# + 1.607858 * HumRatio) / (Pressure / KILO)
  Else
    GetMoistAirVolume = CVErr(2042)
    MyMsgBox ("Humidity ratio is negative")
  End If
End Function


'''''''''''''''''''''''''''''''''''''''
' Moist air density given humidity ratio, dry bulb temperature, and pressure
' ASHRAE Fundamentals (2005) ch. 6 6.8 eqn. 11
' ASHRAE Fundamentals (2009) ch. 1 1.8 eqn. 11
'
Function GetMoistAirDensity(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
  ' GetMoistAirDensity: (o) Moist air density [kg/m3]
  ' TDryBulb: (i) Dry bulb temperature [C]
  ' HumRatio: (i) Humidity ratio [kgH2O/kgAIR]
  ' Pressure: (i) Atmospheric pressure [Pa]
  
  If IsError(HumRatio) Then
    GetMoistAirDensity = CVErr(2042)
  ElseIf HumRatio > 0 Then
    GetMoistAirDensity = (1 + HumRatio) / GetMoistAirVolume(TDryBulb, HumRatio, Pressure)
  Else
    GetMoistAirDensity = CVErr(2042)
    MyMsgBox ("Humidity ratio is negative")
  End If
  
End Function


'*****************************************************************************
'                          Standard atmosphere
'*****************************************************************************

'''''''''''''''''''''''''''''''''''''''/
' Standard atmosphere barometric pressure, given the elevation (altitude)
' ASHRAE Fundamentals (2005) ch. 6 eqn. 3
' ASHRAE Fundamentals (2009) ch. 1 eqn. 3
'
Function GetStandardAtmPressure(ByVal Altitude As Variant) As Variant
  ' GetStandardAtmPressure: (o) standard atmosphere barometric pressure [Pa]
  ' Altitude: (i) altitude [m]
  
  GetStandardAtmPressure = 101325 * (1 - 2.25577 * 10 ^ -5 * Altitude) ^ 5.2559
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Standard atmosphere temperature, given the elevation (altitude)
' ASHRAE Fundamentals (2005) ch. 6 eqn. 4
' ASHRAE Fundamentals (2009) ch. 1 eqn. 4
'
Function GetStandardAtmTemperature(ByVal Altitude As Variant) As Variant
  ' GetStandardAtmTemperature: (o) standard atmosphere dry bulb temperature [C]
  ' Altitude: (i) altitude [m]
  
  GetStandardAtmTemperature = 15 - 0.0065 * Altitude
  
End Function


'''''''''''''''''''''''''''''''''''''''
' Sea level pressure from observed station pressure
' Note: the standard procedure for the US is to use for TDryBulb the average
' of the current station temperature and the station temperature from 12 hours ago
' Hess SL, Introduction to theoretical meteorology, Holt Rinehart and Winston, NY 1959,
' ch. 6.5; Stull RB, Meteorology for scientists and engineers, 2nd edition,
' Brooks/Cole 2000, ch. 1.
'
Function GetSeaLevelPressure(ByVal StnPressure As Variant, ByVal Altitude As Variant, ByVal TDryBulb As Variant) As Variant
 ' GetSeaLevelPressure: (o) sea level barometric pressure [Pa]
 ' StnPressure: (i) observed station pressure [Pa]
 ' Altitude: (i) altitude above sea level [m]
 ' TDryBulb: (i) dry bulb temperature [°C]
 
  ' Calculate average temperature in column of air, assuming a lapse rate
  ' of 6.5 °C/km
  Dim TColumn As Variant
  Dim H As Variant
  
  TColumn = TDryBulb + 0.0065 * Altitude / 2
  
  ' Determine the scale height
  H = 287.055 * CTOK(TColumn) / 9.807

  ' Calculate the sea level pressure
  GetSeaLevelPressure = StnPressure * Exp(Altitude / H)

End Function



'''''''''''''''''''''''''''''''''''''''
' Station pressure from sea level pressure
' This is just the previous function, reversed
'
Function GetStationPressure(ByVal SeaLevelPressure As Variant, ByVal Altitude As Variant, ByVal TDryBulb As Variant) As Variant
  ' GetStationPressure: (o) station pressure [Pa]
  ' SeaLevelPressure: (i) sea level barometric pressure [Pa]
  ' Altitude: (i) altitude above sea level [m]
  ' TDryBulb: (i) dry bulb temperature [°C]
  
  GetStationPressure = SeaLevelPressure / GetSeaLevelPressure(1, Altitude, TDryBulb)
  
End Function
