// ----------------------------------------------------------------------
// Copyright 2023 TimingWalker
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
// Create Date   : 2022-08-10 11:37:09
// Last Modified : 2023-12-24 17:33:52
// Description   : 
// ----------------------------------------------------------------------

package CC_CFG_PKG;

    // XBAR memory map
    localparam CORE_BASE    = SOPHON_PKG::ITCM_BASE;
    localparam CORE_END     = SOPHON_PKG::DTCM_END;

    localparam EXT_DM_BASE  = 32'h0000_0000;
    localparam EXT_DM_END   = 32'h0000_0fff;

    localparam EXT_MEM_BASE = 32'h0000_1000;
    localparam EXT_MEM_END  = 32'h0000_ffff;

    localparam APB_BASE     = 32'h0600_0000;
    localparam APB_END      = 32'h0800_0000;

endpackage

