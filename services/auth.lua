-- Class to fake the auth service
local authService = {
  _VERSION = "1.0"
}

local cjson = require "cjson"
local crypto = require "crypto"
local jwt = require "resty.jwt"

local id_token_key = 'X-USER-ID-TOKEN';

-- private key, No issue in having in code, since this is completely to fake the
-- kong, and user.
local private_jwt = [[
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA55RppLnZIDNXxUdMlJPiHKD81C/DwmTTCcuROFRZasUTw9uA
jdy967sF61/FXBLQXvw+isay1SvHQo3Qy7pkxL2FwyCGhS2Tj3V8t9kGwQIF/QgE
w6FBevsL34tncI0GylEY2+WukcoMqp1Rqq2G9J+YvsBkG66YriAg+cQNSKlC/C+O
p1lzjhuyJuH4GkVKye4HjL1Rvvfcn/evpIR7DKwMnLmedEUBWgki/ubc8fmPmJVP
o0IWmj6vmq5Onrett/nDku31thsq21JzWRi1asTtC5PmYu4T8ClCLSSrHEJIkOGy
iA4xnBDFD2X5tob9y3IwsLYCgYpo3+j00cOGlwIDAQABAoIBAQCTfq5OkWQeIzVa
3A+Fbi8MhuihCI8JKAhV68bhdq/A1ibBjvNw51A7bNHXWRctjnoSlVwMLYPHS+vM
kuCScXQu7nrcjcG/3whlzbGSsvKfSXeg8lN+eh1ng6/LQFGwmNHjWAWaQM6P4n1w
yWQzbfRPp7q0e3sHOovaE3KNQfYn+RfoesTYYlhAai7RS7lI/nCeIgpoHqV80l2f
sUPsYM/nVhwQxa1dhdr1n63cNt0pBHKSPogonLcYZ2a3aS1aXsIF3dwbMvUHYvpJ
rGo3yoCeFsC09E3HjMnc4ftQHTA/K+K9ocakkK1adfUPpXpGSv1n2zteJcD/4fvu
Yts1e+x5AoGBAPyJf0P/0tfB6cFP50n2+xdG/URa6SRBR9cloYjsr11IdJpXh7jj
tER+e0xzjtcwt2owA9GkiN/ntcq33dqtrduTAdiJY5GbeEZDmtXZtV4es2lSZrI8
lENzR2jUk39De7e1AmqX8pI+9mDi1Gbtc2tao9gbE+Qpil4p/WbSlb0zAoGBAOrB
WNtTgHJ0xyaJswlR3B8Pc3E/9xbn+wOCQUbTrAwunODpUS/Pbxtx4jhICQOdfieN
ARMWuqNpSNoZXlSUcmfPzjUU0aMrDfD7yszTPa54BAEx/Em+xbLRbvtUIsxtK5o2
+cF38OAnCDpl6/Ttlb3uXT6zXym8LXoHjW1ONWkNAoGANPXg6rHL1dOk4hWPu8NA
BTGuC5fFLQVDu6r4pW59mGKJkZSpseyO8Y5U7UOOwTJGRM6s/lozGkHNriXBMQsb
WuEJkg++AdtI7fNflVmC36owlfXh858guMSERUfPZvEQEQa06wXSqTjrEoZ/ZNaH
TgxEMB39nevYSMcljVq8bGECgYEA45ZuvrNFY7EzIXl9yRtDfBlOogyRT/O2tsAg
6LltoqHOFX4c520DGmheGJI9qvOUymM5F3iBmMsJhefyO61u/JXKJEv6sWWcLnTt
N4XT1sEjoMUFAbmhkKraHW6EDgwIqYmCuL2/GJC+uV72Uo3DDk94tsDPEXcN37BS
vBWGUkECgYEA9xab9G8NUzYH+gIXeH5B/JD57ZgLMUr+7Lk+LL94Y9bZCL1rxl7X
rIZT4n5rqxdg36UumFIe5H8hzZZRYrDJ6UwDPSZoBQC7IJqM6DqPHE57862Mz64v
UfF+lmubJ/iiTk+YWdz52yy65tDiGT+OPLBI6pFYE7lB14dRpi04C8A=
-----END RSA PRIVATE KEY-----
]]

local public_jwt = [[
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA55RppLnZIDNXxUdMlJPi
HKD81C/DwmTTCcuROFRZasUTw9uAjdy967sF61/FXBLQXvw+isay1SvHQo3Qy7pk
xL2FwyCGhS2Tj3V8t9kGwQIF/QgEw6FBevsL34tncI0GylEY2+WukcoMqp1Rqq2G
9J+YvsBkG66YriAg+cQNSKlC/C+Op1lzjhuyJuH4GkVKye4HjL1Rvvfcn/evpIR7
DKwMnLmedEUBWgki/ubc8fmPmJVPo0IWmj6vmq5Onrett/nDku31thsq21JzWRi1
asTtC5PmYu4T8ClCLSSrHEJIkOGyiA4xnBDFD2X5tob9y3IwsLYCgYpo3+j00cOG
lwIDAQAB
]]

local kid = "single_key"

local keys = {}

keys[1] = {
  kid=kid,
  kty='RSA',
  n='55RppLnZIDNXxUdMlJPiHKD81C_DwmTTCcuROFRZasUTw9uAjdy967sF61_FXBLQXvw-isay1SvHQo3Qy7pkxL2FwyCGhS2Tj3V8t9kGwQIF_QgEw6FBevsL34tncI0GylEY2-WukcoMqp1Rqq2G9J-YvsBkG66YriAg-cQNSKlC_C-Op1lzjhuyJuH4GkVKye4HjL1Rvvfcn_evpIR7DKwMnLmedEUBWgki_ubc8fmPmJVPo0IWmj6vmq5Onrett_nDku31thsq21JzWRi1asTtC5PmYu4T8ClCLSSrHEJIkOGyiA4xnBDFD2X5tob9y3IwsLYCgYpo3-j00cOGlw',
  e='AQAB',
  d='k36uTpFkHiM1WtwPhW4vDIbooQiPCSgIVevG4XavwNYmwY7zcOdQO2zR11kXLY56EpVcDC2Dx0vrzJLgknF0Lu563I3Bv98IZc2xkrLyn0l3oPJTfnodZ4Ovy0BRsJjR41gFmkDOj-J9cMlkM230T6e6tHt7BzqL2hNyjUH2J_kX6HrE2GJYQGou0Uu5SP5wniIKaB6lfNJdn7FD7GDP51YcEMWtXYXa9Z-t3DbdKQRykj6IKJy3GGdmt2ktWl7CBd3cGzL1B2L6SaxqN8qAnhbAtPRNx4zJ3OH7UB0wPyvivaHGpJCtWnX1D6V6Rkr9Z9s7XiXA_-H77mLbNXvseQ',
  p='_Il_Q__S18HpwU_nSfb7F0b9RFrpJEFH1yWhiOyvXUh0mleHuOO0RH57THOO1zC3ajAD0aSI3-e1yrfd2q2t25MB2IljkZt4RkOa1dm1Xh6zaVJmsjyUQ3NHaNSTf0N7t7UCapfykj72YOLUZu1za1qj2BsT5CmKXin9ZtKVvTM',
  q='6sFY21OAcnTHJomzCVHcHw9zcT_3Fuf7A4JBRtOsDC6c4OlRL89vG3HiOEgJA51-J40BExa6o2lI2hleVJRyZ8_ONRTRoysN8PvKzNM9rngEATH8Sb7FstFu-1QizG0rmjb5wXfw4CcIOmXr9O2Vve5dPrNfKbwtegeNbU41aQ0',
  dp='NPXg6rHL1dOk4hWPu8NABTGuC5fFLQVDu6r4pW59mGKJkZSpseyO8Y5U7UOOwTJGRM6s_lozGkHNriXBMQsbWuEJkg--AdtI7fNflVmC36owlfXh858guMSERUfPZvEQEQa06wXSqTjrEoZ_ZNaHTgxEMB39nevYSMcljVq8bGE',
  dq='45ZuvrNFY7EzIXl9yRtDfBlOogyRT_O2tsAg6LltoqHOFX4c520DGmheGJI9qvOUymM5F3iBmMsJhefyO61u_JXKJEv6sWWcLnTtN4XT1sEjoMUFAbmhkKraHW6EDgwIqYmCuL2_GJC-uV72Uo3DDk94tsDPEXcN37BSvBWGUkE',
  qi='9xab9G8NUzYH-gIXeH5B_JD57ZgLMUr-7Lk-LL94Y9bZCL1rxl7XrIZT4n5rqxdg36UumFIe5H8hzZZRYrDJ6UwDPSZoBQC7IJqM6DqPHE57862Mz64vUfF-lmubJ_iiTk-YWdz52yy65tDiGT-OPLBI6pFYE7lB14dRpi04C8A'
}

-- function to add JWT token to every request
function authService.access()
  local jwt_token = jwt:sign(
      private_jwt,
      {
          header={
              typ="JWT",
              alg="RS256",
              kid=kid,
              x5c={
                  public_jwt,
              } },
          payload=ngx.var.userJSON
      }
  )
  ngx.log(ngx.WARN, jwt_token);

  ngx.req.set_header(id_token_key, jwt_token);
end

-- function to supply the token information
function authService.certificate()
  ngx.status = ngx.HTTP_OK
  ngx.header.content_type = "application/json; charset=utf-8"
  ngx.say(cjson.encode({keys = keys}))
  return ngx.exit(ngx.HTTP_OK)
end

function authService.getUserData()
  ngx.status = ngx.HTTP_OK
  ngx.header.content_type = "application/json; charset=utf-8"
  return ngx.say(ngx.var.userJSON)
end

return authService
