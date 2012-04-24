# To change this template, choose Tools | Templates
# and open the template in the editor.

module ActiveRecordHelper
    
  # shift to some other stuff, framework is taking its toll
  def ActiveRecordHelper.round_to_decimal number , decimal_places
    return ((number * (10 ** decimal_places)).to_i).to_f / (10 ** decimal_places).to_f
  end
end
