# $DEBUG = 255 disables all messages.
$zparse2::DEBUG=255;
$zparse2::LOGLEVEL=0;
$zparse2::ZLOCALE = 'ru_RU.cp1251';
$zparse2::LOGIN_LOG = '/www/sites/example.ru/www/login.log';

# set zparse2::$DOCUMENT_ROOT to real document root of your site
# use $ENV{DOCUMENT_ROOT} by defualt

my $host=$ENV{HTTP_HOST};
$host=~s/^.*\.(\w+)$/$1/;

$zparse2::REGLETTER = "/www/sites/example.ru/www/datafiles/regletter.txt";
$zparse2::PWDLETTER = "/www/sites/example.ru/www/datafiles/pwdletter.txt";
$zparse2::DOCUMENT_ROOT = "/www/sites/example.ru/www/html/";
$zparse2::STATIC_ROOT = "/static/";
$zparse2::DATA_FILES_DIR = "/www/sites/example.ru/www/datafiles/";

$zparse2::ZSENDMAILFROMNAME='PEN.RU';
$zparse2::ZSENDMAILFROM='admin@example.ru';

$zparse2::ISS_PREFIX = '/';

$zparse2::ERROR_REDIRECT{'error'}='/../errors/error.html';
$zparse2::ERROR_REDIRECT{'usererror'}='/../errors/user-error.html';
$zparse2::ERROR_REDIRECT{'notfound'}='/../errors/not-found.html';
$zparse2::ERROR_REDIRECT{'accessdenied'}='/../errors/access-denied.html';
$zparse2::ERROR_REDIRECT{'nocookie'}='/../errors/no-cookie.html';
$zparse2::ERROR_REDIRECT{'nocookie_products'}='/../errors/no-cookie_products.html';

$zparse2::DEFAULT_DATA_MODE = 3;

$zparse2::DBD="mysql";
$zparse2::DBNAME="example";
$zparse2::DBUSER="example";
$zparse2::DBUSERPASS="elpmaxe";

$zparse2::GUARD="On";
$zparse2::GUARDDBNAME=$zparse2::DBNAME;
$zparse2::GUARDDBUSER=$zparse2::DBUSER;
$zparse2::GUARDDBUSERPASS=$zparse2::DBUSERPASS;
$zparse2::GUARDPATH="/";

$zparse2::GUARDALLOWANONYMOUS = 1;
$zparse2::GUARDANONYMOUSUSER = 'anonymous';
