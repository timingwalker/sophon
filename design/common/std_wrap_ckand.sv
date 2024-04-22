// ----------------------------------------------------------------------
// Copyright 2024 TimingWalker
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------
//  Date        : 2019-12-20
//  Description : standard cell wrapper
// ----------------------------------------------------------------------

module STD_WRAP_CKAND
(
    input  wire in1_i,
    input  wire in2_i,
    output wire z_o
  );


`ifdef ASIC
  // replace with technolog library
  assign z_o = in1_i & in2_i;

`else
  assign z_o = in1_i & in2_i;
`endif

endmodule
