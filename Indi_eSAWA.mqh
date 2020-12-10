//+------------------------------------------------------------------+
//|                                      Copyright 2016-2020, kenorb |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// User input params.
INPUT string __eSAWA_Indi_Params__ = "-- eSAWA indicator params --";  // >>> eSAWA indicator <<<
INPUT int Indi_eSAWA_CCIPeriod = 14;                                  // CCI period
INPUT int Indi_eSAWA_RSIPeriod = 14;                                  // RSI period
INPUT int Indi_eSAWA_MAPeriod = 14;                                   // MA period
INPUT int Indi_eSAWA_Koef = 8;                                        // Koef
INPUT bool Indi_eSAWA_Arrows = true;                                  // Show arrows
INPUT int Indi_eSAWA_Shift = 0;                                       // Shift

// Structs.

// Defines struct to store indicator parameter values.
struct Indi_eSAWA_Params : public IndicatorParams {
  // Indicator params.
  int cci_period, rsi_period, ma_period, koef;
  // Struct constructors.
  void Indi_eSAWA_Params(int _cci_period, int _rsi_period, int _ma_period, int _koef, int _shift = 0)
      : cci_period(_cci_period), rsi_period(_rsi_period), ma_period(_ma_period), koef(_koef) {
    max_modes = 3;
    custom_indi_name = "eSAWA";
    shift = _shift;
    SetDataSourceType(IDATA_ICUSTOM);
    SetDataValueType(TYPE_DOUBLE);
  };
  void Indi_eSAWA_Params(Indi_eSAWA_Params &_params, ENUM_TIMEFRAMES _tf) {
    this = _params;
    _params.tf = _tf;
  }
  // Getters.
  int GetCCIPeriod() { return cci_period; }
  int GetRSIPeriod() { return rsi_period; }
  int GetMAPeriod() { return ma_period; }
  int GetKoef() { return koef; }
  int GetShift() { return shift; }
  // Setters.
  void SetCCIPeriod(int _value) { cci_period = _value; }
  void SetRSIPeriod(int _value) { rsi_period = _value; }
  void SetMAPeriod(int _value) { ma_period = _value; }
  void SetKoef(int _value) { koef = _value; }
  void SetShift(int _value) { shift = _value; }
};

// Defines struct with default user indicator values.
struct Indi_eSAWA_Params_Defaults : Indi_eSAWA_Params {
  Indi_eSAWA_Params_Defaults()
      : Indi_eSAWA_Params(::Indi_eSAWA_CCIPeriod, ::Indi_eSAWA_RSIPeriod, ::Indi_eSAWA_MAPeriod, ::Indi_eSAWA_Koef,
                          ::Indi_eSAWA_Shift) {}
} indi_esawa_defaults;

/**
 * Implements indicator class.
 */
class Indi_eSAWA : public Indicator {
 public:
  // Structs.
  Indi_eSAWA_Params params;

  /**
   * Class constructor.
   */
  Indi_eSAWA(Indi_eSAWA_Params &_p)
      : params(_p.cci_period, _p.rsi_period, _p.ma_period, _p.koef, _p.shift), Indicator((IndicatorParams)_p) {
    params = _p;
  }
  Indi_eSAWA(Indi_eSAWA_Params &_p, ENUM_TIMEFRAMES _tf)
      : params(_p.cci_period, _p.rsi_period, _p.ma_period, _p.koef, _p.shift), Indicator(NULL, _tf) {
    params = _p;
  }

  /**
   * Gets indicator's params.
   */
  // Indi_eSAWA_Params GetIndiParams() const { return params; }

  /**
   * Returns the indicator's value.
   *
   */
  double GetValue(int _mode, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (params.idstype) {
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, GetSymbol(), GetTf(), params.custom_indi_name, params.tf, params.GetCCIPeriod(),
                         params.GetRSIPeriod(), params.GetMAPeriod(), params.GetKoef(), ::Indi_eSAWA_Arrows, _mode,
                         params.GetShift());
        break;
      default:
        SetUserError(ERR_USER_NOT_SUPPORTED);
        _value = EMPTY_VALUE;
    }
    istate.is_changed = false;
    istate.is_ready = _LastError == ERR_NO_ERROR;
    return _value;
  }

  /**
   * Returns the indicator's struct value.
   */
  IndicatorDataEntry GetEntry(int _shift = 0) {
    long _bar_time = GetBarTime(_shift);
    unsigned int _position;
    IndicatorDataEntry _entry;
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
      for (int _mode = 0; _mode < (int)params.max_modes; _mode++) {
        _entry.values[_mode] = GetValue(_mode, _shift);
      }
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, _entry.GetMin<double>() >= 0);
      if (_entry.IsValid()) {
        idata.Add(_entry, _bar_time);
      }
    }
    return _entry;
  }
};
