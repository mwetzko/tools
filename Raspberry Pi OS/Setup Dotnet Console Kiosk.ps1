# Author: Martin Wetzko
# Thanks to https://reelyactive.github.io/diy/pi-kiosk/ for making this script possible
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
param(
    [Parameter(Mandatory, Position = 0, HelpMessage = "Hostname")]
    [string] $hostname,
    [Parameter(Mandatory, Position = 1, HelpMessage = "Username")]
    [string] $username,
    [Parameter(Mandatory, Position = 2, HelpMessage = "Password")]
    [string] $password,
    [Parameter(Mandatory, Position = 3, HelpMessage = "Publish Folder")]
    [string] $folder,
    [Parameter(Mandatory, Position = 4, HelpMessage = "Startup File")]
    [string] $startup,
    [switch] $reboot
)

$ErrorActionPreference = "Stop"

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

try {

    . ".\EnsurePlink.ps1"
    . ".\EnsurePscp.ps1"

    TestSSH

    $os = ExecSSH "uname -srv"

    Write-Host "Remote machine is: " -NoNewline -ForegroundColor DarkGray
    Write-Host $os -ForegroundColor Green
    
    Write-Host "Update $($os) to latest version..." -ForegroundColor DarkGray

    $null = ExecSSH "sudo apt-get update"

    Write-Host "Installing Mono..." -ForegroundColor DarkGray

    $null = ExecSSH "sudo apt-get install mono-complete --yes"
    
    Write-Host "Upload console app..." -ForegroundColor DarkGray

    $null = ExecSSH "rm -rf ~/kioskapp"
    $null = ExecSSH "mkdir ~/kioskapp"
    
    $folder = Join-Path -Path $folder -ChildPath "*"

    $null = ExecSCP "$($folder)" "/home/$($username)/kioskapp" -folder

    . ".\AutoBash.ps1"

    ExecKioskBash "mono ./kioskapp/$($startup)"
    
    . ".\AutoLogin.ps1"

    if ($reboot) {
        Write-Host "Rebooting remote device..." -ForegroundColor DarkGray
        $null = ExecSSH "sudo shutdown -r 0"
    }
    else {
        Write-Host "Kiosk has been setup. You can now reboot the system." -ForegroundColor Green
    }
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
}