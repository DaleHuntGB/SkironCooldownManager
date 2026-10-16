local SCM = select(2, ...)

local Profiles = SCM.Profiles

local PROFILE_CONSTANTS = SCM.Constants.PROFILES

function SCM.Encode(table)
	local serialized = C_EncodingUtil.SerializeCBOR(table)
	local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.OptimizeForSize)
	local encoded = C_EncodingUtil.EncodeBase64(compressed)

	return encoded
end

function SCM.Decode(importString)
	local decoded = C_EncodingUtil.DecodeBase64(importString)
	local decompressed = C_EncodingUtil.DecompressString(decoded)
	local data = C_EncodingUtil.DeserializeCBOR(decompressed)

	return data
end

function Profiles.EncodeExport(exportType, data, excludeIcons)
	if exportType == PROFILE_CONSTANTS.EXPORT_TYPE.GLOBAL_SETTINGS then
		data = { globalSettings = data }
	elseif exportType == PROFILE_CONSTANTS.EXPORT_TYPE.GLOBAL_ANCHORS then
		data = { globalAnchors = data }
	end

	data.payloadVersion = PROFILE_CONSTANTS.PAYLOAD_VERSION
	data.excludeIcons = excludeIcons or nil

	local prefix = string.format("!%s:%d:%d!", PROFILE_CONSTANTS.PREFIX, PROFILE_CONSTANTS.DATA_VERSION, exportType)

	return prefix .. SCM.Encode(data)
end

function Profiles.DecodeImport(importString)
	local parameterString, dataString = importString:match("^!([^!]+)!(.+)$")

	if not parameterString or not dataString then
		return
	end

	local prefix, version, typeStr = strsplit(":", parameterString)
	local typeID = tonumber(typeStr)
	local versionID = tonumber(version)

	if not typeID or prefix ~= PROFILE_CONSTANTS.PREFIX or versionID ~= PROFILE_CONSTANTS.DATA_VERSION then
		print("Invalid Import String")
		return
	end

	local success, data = pcall(SCM.Decode, dataString)

	if not success or type(data) ~= "table" then
		return
	end

	if data.payloadVersion then
		if data.payloadVersion ~= PROFILE_CONSTANTS.PAYLOAD_VERSION then
			print("Unsupported Import Format")
			return
		end
	elseif typeID == PROFILE_CONSTANTS.EXPORT_TYPE.GLOBAL_SETTINGS then
		data = { globalSettings = data }
	elseif typeID == PROFILE_CONSTANTS.EXPORT_TYPE.GLOBAL_ANCHORS then
		data = { globalAnchors = data }
	elseif not (data.profileData or data.resourceBarSettings or data.castBarSettings or data.globalSettings or data.globalAnchors or typeID == PROFILE_CONSTANTS.EXPORT_TYPE.EVERYTHING) then
		data = { profileData = data }
	end

	if typeID == PROFILE_CONSTANTS.EXPORT_TYPE.EVERYTHING then
		typeID = PROFILE_CONSTANTS.EXPORT_TYPE.ALL
	end

	return typeID, data
end
