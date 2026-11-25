# Source fishtape operators
functions @echo | string collect | source
functions @test | string collect | source
# Source our functions
source (dirname (status filename))/../functions/*.fish
