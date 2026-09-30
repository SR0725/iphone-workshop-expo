import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import os from 'node:os';

test('create, validate, persist, edit, filter and delete', async ({page},info) => {
  const errors:string[]=[]; page.on('pageerror',e=>errors.push(e.message));
  await page.goto('/');
  await page.getByRole('button',{name:'新增紀錄',exact:true}).click();
  await page.getByRole('button',{name:'儲存紀錄',exact:true}).click();
  await expect(page.getByText('請先填寫標題',{exact:true})).toBeVisible();
  await page.getByRole('textbox',{name:'標題',exact:true}).fill('讀完一本書');
  await page.getByRole('textbox',{name:'內容',exact:true}).fill('今天讀了十頁，留下自己的心得。');
  await page.getByRole('radio',{name:'分類靈感'}).click();
  await page.getByRole('button',{name:'儲存紀錄',exact:true}).click();
  await expect(page.getByText('已儲存',{exact:true})).toBeVisible();
  await page.reload();
  await expect(page.getByText('讀完一本書',{exact:true})).toBeVisible();
  await page.getByRole('button',{name:'編輯讀完一本書'}).click();
  await page.getByRole('textbox',{name:'標題',exact:true}).fill('讀完十頁書');
  await page.getByRole('button',{name:'儲存紀錄',exact:true}).click();
  await page.getByRole('tab',{name:'篩選工作'}).click();
  await expect(page.getByText('還沒有工作紀錄',{exact:true})).toBeVisible();
  await page.getByRole('tab',{name:'篩選靈感'}).click();
  await expect(page.getByText('讀完十頁書',{exact:true})).toBeVisible();
  fs.mkdirSync('evidence',{recursive:true});
  await page.screenshot({path:`evidence/${process.platform}-${info.project.name}.png`,fullPage:true});
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth)).toBeTruthy();
  await page.getByRole('button',{name:'刪除讀完十頁書'}).click();
  await page.getByRole('button',{name:'取消刪除'}).click();
  await expect(page.getByText('讀完十頁書',{exact:true})).toBeVisible();
  await page.getByRole('button',{name:'刪除讀完十頁書'}).click();
  await page.getByRole('button',{name:'確認刪除'}).click();
  await expect(page.getByText('已刪除',{exact:true})).toBeVisible();
  await page.reload();
  await expect(page.getByText('記下今天第一件小事',{exact:true})).toBeVisible();
  expect(errors).toEqual([]);
  fs.writeFileSync('evidence/environment.json',JSON.stringify({platform:process.platform,release:os.release(),arch:os.arch(),node:process.version,at:new Date().toISOString(),runner:process.env.RUNNER_OS||'local'},null,2));
});

test('corrupted storage is not overwritten',async({page})=>{
  await page.goto('/');
  await page.evaluate(()=>localStorage.setItem('small-things-workshop-v1','invalid-json'));
  await page.reload();
  await expect(page.getByText('無法讀取已存的紀錄，原始資料尚未變更。',{exact:true})).toBeVisible();
  await expect(page.getByRole('button',{name:'新增紀錄'})).toBeDisabled();
  expect(await page.evaluate(()=>localStorage.getItem('small-things-workshop-v1'))).toBe('invalid-json');
});
