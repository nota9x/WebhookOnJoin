--[[
#################################################################################
#                              a9x Development                                  #
#                                                                               #
# This script is developed by a9x Development and is licensed under the GPL-3.0 #
# (GNU General Public License v3.0).                                            #
#                                                                               #
# This script is provided "as is", without warranty of any kind, express or     #
# implied, including but not limited to the warranties of merchantability,      #
# fitness for a particular purpose and noninfringement. In no event shall the   #
# authors or copyright holders be liable for any claim, damages or other        #
# liability, whether in an action of contract, tort or otherwise, arising from, #
# out of or in connection with the script or the use or other dealings in the   #
# script.                                                                       #
#                                                                               #
# You should have received a copy of the GNU General Public License along with  #
# this script. If not, see https://www.gnu.org/licenses/.                       #
#################################################################################
]]

-- LocalScript (placed in StarterPlayerScripts or StarterCharacterScripts)
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- RemoteEvent to communicate with the server
local inputTypeEvent = game.ReplicatedStorage:WaitForChild("InputTypeEvent")

local function determineInputType()
    if UserInputService.GamepadEnabled then
        return "Gamepad"
    elseif UserInputService.TouchEnabled then
        return "Touchscreen"
    elseif UserInputService.VREnabled then
        return "VR"
    else
        return "Keyboard and Mouse"
    end
end

-- Detect input type and send to server
local inputType = determineInputType()
inputTypeEvent:FireServer(inputType)