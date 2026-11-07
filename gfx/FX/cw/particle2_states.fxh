RasterizerState RasterizerStateNoCulling
{
	CullMode = "none"
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}

DepthStencilState DepthStencilStateNoDepth
{
	DepthEnable = no
	DepthWriteEnable = no
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}

BlendState AdditiveBlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "ONE"
	WriteMask = "RED|GREEN|BLUE|ALPHA"
	BlendOpAlpha = "max"
}

BlendState PreMultipliedAlpha
{
    BlendEnable = yes;
    SourceBlend = "ONE"
    DestBlend = "INV_SRC_ALPHA"
    BlendOp = "ADD"
    SourceAlpha = "ONE"
    DestAlpha = "INV_SRC_ALPHA"
    BlendOpAlpha = "ADD"
    WriteMask = "RED|GREEN|BLUE|ALPHA"
}

BlendState BlendAdd
{
    BlendEnable = yes
    SourceBlend = "ONE"
    DestBlend = "ONE"
    BlendOp = "ADD"
    SourceAlpha = "ONE"
    DestAlpha = "ONE"
    BlendOpAlpha = "ADD"
    WriteMask = "RED|GREEN|BLUE|ALPHA"
}