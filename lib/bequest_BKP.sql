select * from  public.installation_configs
WHERE name in ('INSTALLATION_PRICING_PLAN', 'INSTALLATION_PRICING_PLAN_QUANTITY', 'INSTALLATION_IDENTIFIER');


  id |                name                |                                             serialized_value                                             |         created_at         |         updated_at         | locked
----+------------------------------------+----------------------------------------------------------------------------------------------------------+----------------------------+----------------------------+--------
 47 | INSTALLATION_PRICING_PLAN          | "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: community\n"                            | 2025-12-08 13:09:25.730592 | 2025-12-08 13:09:25.730592 | t
 48 | INSTALLATION_PRICING_PLAN_QUANTITY | "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 0\n"                                    | 2025-12-08 13:09:25.737598 | 2025-12-08 13:09:25.737598 | t
 85 | INSTALLATION_IDENTIFIER            | "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 87b58a4c-f749-4435-8622-574f22f97302\n" | 2025-12-09 12:00:35.357837 | 2025-12-09 12:00:35.357837 | t


CHATWOOT_HUB_URL=https://oriondesign.art.br/setup#


 
UPDATE public.installation_configs 
SET serialized_value = '"--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: enterprise\n"' 
WHERE name = 'INSTALLATION_PRICING_PLAN';

UPDATE public.installation_configs 
SET serialized_value = '"--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 10000\n"' 
WHERE name = 'INSTALLATION_PRICING_PLAN_QUANTITY';

UPDATE public.installation_configs 
SET serialized_value = '"--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: e04t63ee-5gg8-4b94-8914-ed8137a7d938\n"' 
WHERE name = 'INSTALLATION_IDENTIFIER';